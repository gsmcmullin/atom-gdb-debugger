{Emitter, CompositeDisposable} = require 'atom'

class Exec
    state: 'EXITED'

    constructor: (@gdb) ->
        @emitter = new Emitter
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.onAsyncExec(@_onExec.bind(this))
        @subscriptions.add @gdb.onAsyncNotify(@_onNotify.bind(this))

    onStateChanged: (cb) ->
        @emitter.on 'state-changed', cb
    onFrameChanged: (cb) ->
        @emitter.on 'frame-changed', cb

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
            .then (result) =>
                @emitter.emit 'frame-changed', result.frame

    _setState: (state) ->
        if state == @state then return
        @state = state
        @emitter.emit 'state-changed', state

    _onExec: ([cls, results]) ->
        switch cls
            when 'running'
                @emitter.emit 'frame-changed', {}
                @_setState 'RUNNING'
            when 'stopped'
                @emitter.emit 'frame-changed', results.frame or {}
                @_setState 'STOPPED'
                if results.reason? and results.reason.startsWith 'exited'
                    @_setState 'EXITED'

    _onNotify: ([cls, results]) ->
        switch cls
            when 'thread-exited'
                @emitter.emit 'frame-changed', {}
                @_setState 'EXITED'
            when 'thread-selected'
                if @state == 'RUNNING'
                    @_setState 'STOPPED'

module.exports = Exec
