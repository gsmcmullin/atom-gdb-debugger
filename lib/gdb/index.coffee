child_process = require 'child_process'
{EventEmitter} = require 'events'

{Parser} = require './gdbmi.js'

class GDB extends EventEmitter
    state: 'DISCONNECTED'
    target_state: 'EXITED'
    child: null
    next_token: 0
    cmdq: []
    partial_line: ''
    cmdline: 'gdb'

    constructor: ->
        @parser = new Parser

    _set_state: (state) ->
        if state == @state then return
        @state = state
        @emit 'state-changed', state

    _set_target_state: (state) ->
        if state == @target_state then return
        @target_state = state
        @emit 'target-state-changed', state

    cstr: (s)->
        esc = ''
        for c in s
            switch c
                when '"' then c = '\\"'
                when '\\' then c = '\\\\'
            esc += c
        return "\"#{esc}\""

    connect: ->
        # Spawn the GDB child process and connect up event handlers
        @child = child_process.spawn @cmdline, ['-n', '--interpreter=mi']
        @child.stdout.on 'data', (data) => @_raw_output_handler(data)
        @child.stderr.on 'data', (data) => @_raw_output_handler(data)
        @child.on 'exit', => @_child_exited()
        @_set_state 'IDLE'
        if @cwd?
            @send_mi "-environment-cd #{@cstr(@cwd)}"
        if @file?
            @send_mi "-file-exec-and-symbols #{@cstr(@file)}"
        if @init?
            for cmd in @init.split '\n'
                @send_cli cmd

    disconnect: ->
        # Politely request the GDB child process to exit
        # First interrupt the target if it's running
        if @state == 'DISCONNECTED' then return
        if @target_state == 'RUNNING'
            @interrupt()
        @send_mi '-gdb-exit'

    _raw_output_handler: (data) ->
        # Split lines and keep patial line for next time
        data = @partial_line + data.toString()
        lines = data.split '\n'
        @partial_line = lines.slice(-1)
        lines = lines.slice 0, -1
        for line in lines
            @_line_output_handler line

    _line_output_handler: (line) ->
        # Handle line buffered output from GDB child process
        @emit 'gdbmi-raw', line
        r = @parser.parse line
        if not r? then return
        @emit 'gdbmi-ast', r
        switch r.type
            when 'OUTPUT' then @emit 'console-output', r.cls, r.cstring
            when 'ASYNC' then @_async_record_handler r.cls, r.rcls, r.results
            when 'RESULT' then @_result_record_handler r.cls, r.results

    _async_record_handler: (cls, rcls, results) ->
        #console.log "#{cls} (#{rcls}): #{JSON.stringify(results)}"
        signal = 'gdbmi-' + cls.toLowerCase()
        @emit signal, results

        if cls != 'EXEC' then return
        switch rcls
            when 'running'
                @emit 'frame-changed', {}
                @_set_target_state 'RUNNING'
                @cmdq = []
                # TODO emit frame-changed with no info
            when 'stopped'
                @emit 'frame-changed', results.frame
                @_set_target_state 'STOPPED'
                if results.reason? and results.reason.startsWith 'exited'
                    @_set_target_state 'EXITED'

    _result_record_handler: (cls, results) ->
        c = @cmdq.shift()
        if cls == 'error'
            c.reject results.msg
            @_flush_queue()
            return
        c.resolve results
        @_drain_queue()

    _child_exited: () ->
        # Clean up state if/when GDB child process exits
        console.log 'Child exited'
        @emit 'frame-changed', {}
        @_set_state 'DISCONNECTED'
        @_set_target_state 'EXITED'
        delete @child

    send_mi: (cmd, quiet) ->
        # Send an MI command to GDB
        new Promise (resolve, reject) =>
            cmd = @next_token + cmd
            @next_token += 1
            @cmdq.push {quiet: quiet, cmd: cmd, resolve:resolve, reject: reject}
            if @state == 'IDLE'
                @_drain_queue()

    _drain_queue: ->
        c = @cmdq[0]
        if not c?
            @_set_state 'IDLE'
            return
        @emit 'gdbmi-raw', c.cmd
        @child.stdin.write c.cmd + '\n'
        @_set_state 'BUSY'

    _flush_queue: ->
        for c in @cmdq
            c.reject 'Flushed due to previous errors'
        @cmdq = []
        @_set_state 'IDLE'

    send_cli: (cmd) ->
        @send_mi "-interpreter-exec console #{@cstr(cmd)}"

    start: ->
        @send_mi '-break-insert -t main'
        @send_mi '-exec-run'

    continue: -> @send_mi '-exec-continue'
    next: -> @send_mi '-exec-next'
    step: -> @send_mi '-exec-step'
    finish: -> @send_mi '-exec-finish'

    interrupt: ->
        # Interrupt the target if running
        if @target_state != 'RUNNING' then return
        @child.kill 'SIGINT'

module.exports = GDB
