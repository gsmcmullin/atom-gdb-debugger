{View} = require 'atom-space-pen-views'

module.exports =
class GdbCliView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @gdb.on 'console-output', (stream, text) =>
            @_text_output(text)

    @content: (gdb) ->
        @div class: 'gdb-cli', =>
            @div class: 'scrolled-window', outlet: 'scrolled_window', =>
                @pre outlet: 'console'
            @div class: 'gdb-cli-input', =>
                @code '(gdb)'
                @input class: 'native-key-bindings', keypress: 'do_cli', outlet: 'cmd'

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
