{Emitter, Disposable, CompositeDisposable} = require 'event-kit'
_ = require 'underscore'

class Breakpoint
    constructor: (@gdb, bkpt) ->
        @emitter = new Emitter
        _.extend this, bkpt

    onChanged: (cb) ->
        @emitter.on 'changed', cb
    onDeleted: (cb) ->
        @emitter.on 'deleted', cb

    remove: ->
        @gdb.send_mi "-break-delete #{@number}"
            .then => @_deleted()

    _changed: (bkpt) ->
        _.extend this, bkpt
        @emitter.emit 'changed'

    _deleted: ->
        @emitter.emit 'deleted'

module.exports =
class BreakpointManager
    constructor: (@gdb) ->
        @breaks = {}
        @observers = []
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.onAsyncNotify(@_onAsyncNotify.bind(this))
        @subscriptions.add @gdb.exec.onStateChanged @_onStateChanged.bind(this)

    observe: (cb) ->
        for id, bkpt of @breaks
            cb id, bkpt
        @observers.push cb
        return new Disposable () ->
            @observers.splice(@observers.indexOf(cb), 1)

    insert: (pos) ->
        @gdb.send_mi "-break-insert #{pos}"
            .then ({bkpt}) =>
                @_add bkpt

    insertWatch: (expr, hook) ->
        @gdb.send_mi "-break-watch #{expr}"
            .then ({wpt}) =>
                if hook? then hook(wpt.number)
                @gdb.send_mi "-break-info #{wpt.number}"
            .then (results) =>
                @_add results.BreakpointTable.body.bkpt[0]

    toggle: (file, line) ->
        for id, bkpt of @breaks
            if bkpt.fullname == file and +bkpt.line == line
                bkpt.remove()
                removed = true
        if not removed
            @insert "#{file}:#{line}"

    _add: (bkpt) ->
        bkpt = @breaks[bkpt.number] = new Breakpoint(@gdb, bkpt)
        bkpt.onDeleted => delete @breaks[bkpt.number]
        for cb in @observers
            cb bkpt.number, bkpt
        bkpt

    _onAsyncNotify: ([cls, {id, bkpt}]) ->
        switch cls
            when 'breakpoint-created'
                @_add bkpt
            when 'breakpoint-modified'
                @breaks[bkpt.number]._changed(bkpt)
            when 'breakpoint-deleted'
                @breaks[id]._deleted()
                delete @breaks[id]

    _onStateChanged: ([state]) ->
        if state == 'DISCONNECTED'
            for id, bkpt of @breaks
                bkpt._deleted()
            @breaks = {}
