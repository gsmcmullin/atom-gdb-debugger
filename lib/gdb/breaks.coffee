{Emitter, Disposable, CompositeDisposable} = require 'atom'

class Breaks
    breaks: {}
    observers: []

    constructor: (@gdb) ->
        @emitter = new Emitter
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.onAsyncNotify(@_onNotify.bind(this))
        @observe @_selfObserve.bind(this)

    observe: (cb) ->
        for id, bkpt of @breaks
            cb id, bkpt
        @observers.push cb
        return new Disposable () ->
            @observers.splice(@observers.indexOf(cb), 1)

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

    _selfObserve: (id, bkpt) ->
        if not bkpt?
            delete @breaks[id]
            return
        @breaks[id] = bkpt

module.exports = Breaks
