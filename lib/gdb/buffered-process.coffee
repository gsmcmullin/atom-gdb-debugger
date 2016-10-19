child_process = require 'child_process'

class BufferedProcess
    partialLine: ''

    constructor: ({@command, @args, @stdout, @exit}, ok) ->

    _spawn: () ->
        new Promise (resolve, reject) =>
            @process = child_process.spawn @command, @args
            @process.stdout.on 'data', (data) => @_stdout(data)

            ok = =>
                @process.removeListener 'error', error
                resolve this
            error = (err) =>
                @process.stdout.removeListener 'data', ok
                reject err
            @process.stdout.once 'data', ok
            @process.once 'error', error

            @process.on 'exit', => @exit

    stdin: (line) ->
        @process.stdin.write line + '\n'

    _stdout: (data) ->
        # Split lines and keep patial line for next time
        data = @partialLine + data.toString()
        lines = data.split '\n'
        @partialLine = lines.slice(-1)
        lines = lines.slice 0, -1
        for line in lines
            @stdout line

    kill: (signal) ->
        @process.kill signal

module.exports = (options) ->
    new BufferedProcess(options)._spawn()
