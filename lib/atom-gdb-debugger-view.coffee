{View} = require 'atom-space-pen-views'

module.exports =
class AtomGdbDebuggerView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @gdb.on 'console-output', (stream, text) =>
            @_text_output(text)

        @gdb.on 'state-changed', (state) =>
            @state.text state
            if state == 'DISCONNECTED'
                @disconnect.hide()
                @connect.show()
            else
                @disconnect.show()
                @connect.hide()

        @gdb.on 'target-state-changed', (state) =>
            @target_state.text state

        @gdb.on 'frame-changed', (frame) =>
            if not frame?
                @frame.text '(no frame)'
                return
            @frame.text "#{frame.file}:#{frame.line}"

    @content: ->
        @div class: 'gdb-debugger-panel', =>
            @div =>
                @button 'Connect', click: 'do_connect', outlet: 'connect'
                @button 'Disconnect', click: 'do_disconnect', outlet: 'disconnect', style: 'display: none'
                @div class: 'state-display', =>
                    @span '(no frame)', outlet: 'frame'
                    @span 'DISCONNECTED', outlet: 'state'
                    @span 'EXITED', outlet: 'target_state'
            @div class: 'gdb-cli', =>
                @div class: 'scrolled-window', outlet: 'scrolled_window', =>
                    @pre outlet: 'console'
                @div class: 'gdb-cli-input', =>
                    @code '(gdb)'
                    @input class: 'native-key-bindings', keypress: 'do_cli', outlet: 'cmd'

    do_connect: ->
        @console.text ''
        @gdb.connect()

    do_disconnect: -> @gdb.disconnect()

    do_cli: (event) ->
        if event.charCode == 13
            cmd = @cmd.val()
            @cmd.val ''
            @_text_output "(gdb) #{cmd}\n"
            @gdb.send_cli cmd

    _text_output: (text) ->
        text = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        @console.append(text)
        @scrolled_window.prop 'scrollTop', @console.height() - @scrolled_window.height()
