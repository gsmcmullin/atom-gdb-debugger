{Emitter, Disposable, CompositeDisposable} = require 'atom'

class Breaks
    constructor: (@gdb) ->
        @breaks = {}
        @observers = []
        @emitter = new Emitter
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.onAsyncNotify(@_onNotify.bind(this))
        @subscriptions.add @gdb.exec.onStateChanged @_onStateChanged.bind(this)
        @observe @_selfObserve.bind(this)

    observe: (cb) ->
        for id, bkpt of @breaks
            cb id, bkpt
        @observers.push cb
        return new Disposable () ->
            @observers.splice(@observers.indexOf(cb), 1)

    insert: (pos) ->
        @gdb.send_mi "-break-insert #{pos}"
            .then ({bkpt}) =>
                @_notifyObservers bkpt.number, bkpt

    insertWatch: (expr) ->
        @gdb.send_mi "-break-watch #{expr}"
            .then ({wpt}) ->
                return wpt.number

    remove: (id) ->
        @gdb.send_mi "-break-delete #{id}"
            .then () =>
                @_notifyObservers id

    toggle: (file, line) ->
        for id, bkpt of @breaks
            if bkpt.fullname == file and +bkpt.line == line
                @remove id
                removed = true
        if not removed
            @insert "#{file}:#{line}"

    _notifyObservers: (id, bkpt) ->
        for cb in @observers
            cb id, bkpt

    _onNotify: ([cls, results]) ->
        switch cls
            when 'breakpoint-deleted'
                @_notifyObservers results.id
            when 'breakpoint-created'
                @_notifyObservers results.bkpt.number, results.bkpt
            when 'breakpoint-modified'
                @_notifyObservers results.bkpt.number, results.bkpt

    _onStateChanged: ([state]) ->
        if state == 'DISCONNECTED'
            for id, bkpt of @breaks
                @_notifyObservers id
            @breaks = {}

    _selfObserve: (id, bkpt) ->
        if not bkpt?
            delete @breaks[id]
            return
        @breaks[id] = bkpt

module.exports = Breaks
