child_process = require 'child_process'
{EventEmitter} = require 'events'

{Parser} = require './gdbmi.js'

class GDB extends EventEmitter
    constructor: (@cmdline) ->
        @parser = new Parser
        @cmdq = []
        @next_token = 0
        @state = 'DISCONNECTED'
        @target_state = 'EXITED'
        @partial_line = ''

    connect: ->
        # Spawn the GDB child process and connect up event handlers
        @child = child_process.spawn @cmdline, ['-n', '--interpreter=mi']
        @child.stdout.on 'data', (data) => @_raw_output_handler(data)
        @child.stderr.on 'data', (data) => @_raw_output_handler(data)
        @child.on 'exit', @_child_exited
        @state = 'BUSY'

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
        ast = @parser.parse(line+'\n')
        for r in ast
            @emit 'gdbmi-ast', r
            switch r.type
                when 'OUTPUT' then @emit 'console-output', r.cls, r.cstring
                when 'ASYNC' then @_async_record_handler r.cls, r.rcls, r.results
                when 'RESULT' then @_result_record_handler r.cls, r.results
        if line.search('\\(gdb\\)') >= 0
            @_drain_queue()

    _async_record_handler: (cls, rcls, results) ->
        #console.log "#{cls} (#{rcls}): #{JSON.stringify(results)}"
        signal = 'gdbmi-' + cls.toLowerCase()
        @emit signal, results

        if cls != 'EXEC' then return
        switch rcls
            when 'running'
                @target_state = 'RUNNING'
                @cmdq = []
                # TODO emit frame-changed with no info
            when 'stopped'
                @target_state = 'STOPPED'
                if results.reason.startsWith 'exited'
                    @target_state = 'EXITED'

    _result_record_handler: (cls, results) ->
        console.log "#{cls}: #{JSON.stringify(results)}"

    _child_exited: () ->
        # Clean up state if/when GDB child process exits
        console.log 'Child exited'
        @state = 'DISCONNECTED'
        @target_state = 'EXITED'
        delete @child

    send_mi: (cmd, result_cb, quiet) ->
        # Send an MI command to GDB
        cmd = @next_token + cmd
        @next_token += 1
        @cmdq.push {quiet: quiet, cmd: cmd, cb:result_cb}
        if @state == 'IDLE'
            @_drain_queue()

    _drain_queue: ->
        c = @cmdq.shift()
        if not c?
            @state = 'IDLE'
            return
        @child.stdin.write c.cmd + '\n'
        @state = 'BUSY'

    start: ->
        @send_mi '-break-insert -t main'
        @send_mi '-exec-run'

    continue: -> @send_mi '-exec-continue'
    next: -> @send_mi '-exec-next'
    step: -> @send_mi '-exec-step'
    finish: -> @send_mi '-exec-finish'

    interrupt: ->
        # Interrupt the target if running
        if @state != 'RUNNING' then return
        @child.kill 'SIGINT'

module.exports = GDB

gdb = new GDB('gdb')
gdb.on 'console-output', (stream, data) ->
    process.stdout.write data
gdb.connect()
gdb.disconnect()
