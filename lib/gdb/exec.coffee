{Emitter, CompositeDisposable} = require 'atom'

class Exec
    state: 'DISCONNECTD'

    constructor: (@gdb) ->
        @emitter = new Emitter
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.onAsyncExec(@_onExec.bind(this))
        @subscriptions.add @gdb.onAsyncNotify(@_onNotify.bind(this))

    onStateChanged: (cb) ->
        @emitter.on 'state-changed', cb

    start: ->
        @gdb.send_mi '-break-insert -t main'
        @gdb.send_mi '-exec-run'

    continue: -> @gdb.send_mi '-exec-continue'
    next: -> @gdb.send_mi '-exec-next'
    step: -> @gdb.send_mi '-exec-step'
    finish: -> @gdb.send_mi '-exec-finish'

    interrupt: ->
        # Interrupt the target if running
        if @state != 'RUNNING' then return
        @gdb.child.process.kill 'SIGINT'

    backtrace: () ->
        @gdb.send_mi '-stack-list-frames'
            .then (result) ->
                return result.stack.frame

    selectFrame: (level) ->
        @gdb.send_mi "-stack-select-frame #{level}"
        @gdb.send_mi "-stack-info-frame"
            .then ({frame}) =>
                @_setState @state, frame

    _setState: (state, frame) ->
        @state = state
        @emitter.emit 'state-changed', [state, frame]

    _onExec: ([cls, {reason, frame}]) ->
        switch cls
            when 'running'
                @_setState 'RUNNING'
            when 'stopped'
                @_setState 'STOPPED', frame
                if reason? and reason.startsWith 'exited'
                    @_setState 'EXITED'

    _onNotify: ([cls, results]) ->
        switch cls
            when 'thread-exited'
                @_setState 'EXITED'
            when 'thread-selected'
                if @state == 'RUNNING'
                    @_setState 'STOPPED'

    _connected: ->
        @_setState 'EXITED'
    _disconnected: ->
        @_setState 'DISCONNECTED'

module.exports = Exec
