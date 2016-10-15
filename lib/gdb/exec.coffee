{Emitter, CompositeDisposable} = require 'atom'

class Exec
    state: 'DISCONNECTED'
    threadGroups: {}

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

    continue: ->
        if @state == 'EXITED'
            @gdb.send_mi '-exec-run'
        else
            @gdb.send_mi '-exec-continue'

    next: -> @gdb.send_mi '-exec-next'
    step: -> @gdb.send_mi '-exec-step'
    finish: -> @gdb.send_mi '-exec-finish'

    interrupt: ->
        # Interrupt the target if running
        if @state != 'RUNNING' then return
        # There is no hope here for Windows.  See issue #4
        if @gdb.config.isRemote
            @gdb.child.process.kill 'SIGINT'
        else
            for id, group of @threadGroups
                process.kill group.pid, 'SIGINT'


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
            when 'thread-group-started'
                @threadGroups[results.id] = pid: +results.pid, threads: []
            when 'thread-created'
                @threadGroups[results['group-id']].threads.push results.id
            when 'thread-exited'
                threads = @threadGroups[results['group-id']].threads
                index = threads.indexOf results.id
                threads.splice index, 1
            when 'thread-group-exited'
                delete @threadGroups[results.id]
                if Object.keys(@threadGroups).length == 0
                    @_setState 'EXITED'

    _connected: ->
        @_setState 'EXITED'
    _disconnected: ->
        @_setState 'DISCONNECTED'

module.exports = Exec
