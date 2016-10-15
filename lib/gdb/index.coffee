{Emitter, BufferedProcess} = require 'atom'
{Parser} = require './gdbmi.js'
Exec = require './exec'
Breaks = require './breaks'

class GDB
    state: 'DISCONNECTED'
    child: null
    next_token: 0
    cmdq: []
    cmdline: 'gdb'

    constructor: ->
        @parser = new Parser
        @emitter = new Emitter
        @exec = new Exec(this)
        @breaks = new Breaks(this)

    onConsoleOutput: (cb) ->
        @emitter.on 'console-output', cb
    onGdbmiRaw: (cb) ->
        @emitter.on 'gdbmi-raw', cb

    onAsyncExec: (cb) ->
        @emitter.on 'async-exec', cb
    onAsyncNotify: (cb) ->
        @emitter.on 'async-notify', cb
    onAsyncStatus: (cb) ->
        @emitter.on 'async-status', cb

    cstr: (s)->
        esc = ''
        for c in s
            switch c
                when '"' then c = '\\"'
                when '\\' then c = '\\\\'
            esc += c
        return "\"#{esc}\""

    connect: ->
        if @child? then @child.kill()
        # Spawn the GDB child process and connect up event handlers
        @child = new BufferedProcess
            command: @cmdline
            args: ['-n', '--interpreter=mi']
            stdout: @_raw_output_handler.bind(this)
            stderr: @_raw_output_handler.bind(this)
            exit: @_child_exited.bind(this)
        @child.onWillThrowError (x) =>
            @emitter.emit 'console-output', ['LOG', x.error.toString()+'\n']
            @_child_exited()
            x.handle()
        @exec._connected()
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
        if not @child? then return
        if @exec.state == 'RUNNING'
            @exec.interrupt()
        @send_mi '-gdb-exit'

    _raw_output_handler: (data) ->
        lines = data.split('\n').slice(0, -1)
        for line in lines
            @_line_output_handler line

    _line_output_handler: (line) ->
        # Handle line buffered output from GDB child process
        @emitter.emit 'gdbmi-raw', line
        try
            r = @parser.parse line
        catch err
            @emitter.emit 'console-output', ['CONSOLE', line + '\n']
        if not r? then return
        @emitter.emit 'gdbmi-ast', r
        switch r.type
            when 'OUTPUT' then @emitter.emit 'console-output', [r.cls, r.cstring]
            when 'ASYNC' then @_async_record_handler r.cls, r.rcls, r.results
            when 'RESULT' then @_result_record_handler r.cls, r.results

    _async_record_handler: (cls, rcls, results) ->
        signal = 'async-' + cls.toLowerCase()
        @emitter.emit signal, [rcls, results]

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
        @exec._disconnected()
        @_flush_queue()
        delete @child

    send_mi: (cmd, quiet) ->
        # Send an MI command to GDB
        if not @child?
            return Promise.reject 'Not connected'
        if @exec.state == 'RUNNING'
            return Promise.reject "Can't send commands while target is running"
        new Promise (resolve, reject) =>
            cmd = @next_token + cmd
            @next_token += 1
            @cmdq.push {quiet: quiet, cmd: cmd, resolve:resolve, reject: reject}
            if @cmdq.length == 1
                @_drain_queue()

    _drain_queue: ->
        c = @cmdq[0]
        if not c? then return
        @emitter.emit 'gdbmi-raw', c.cmd
        @child.process.stdin.write c.cmd + '\n'

    _flush_queue: ->
        for c in @cmdq
            c.reject 'Flushed due to previous errors'
        @cmdq = []

    send_cli: (cmd) ->
        @send_mi "-interpreter-exec console #{@cstr(cmd)}"

module.exports = GDB
