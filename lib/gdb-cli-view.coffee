{View, $} = require 'atom-space-pen-views'

module.exports =
class GdbCliView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @gdb.onConsoleOutput ([stream, text]) =>
            switch stream
                when 'LOG' then cls = 'text-error'
                when 'TARGET' then cls = 'text-info'
            @_text_output(text, cls)

    @content: (gdb) ->
        @div class: 'gdb-cli', =>
            @div class: 'scrolled-window', outlet: 'scrolled_window', =>
                @pre outlet: 'console'
            @div class: 'gdb-cli-input', =>
                @pre '(gdb)'
                @input class: 'native-key-bindings', keypress: 'do_cli', outlet: 'cmd'

    do_cli: (event) ->
        if event.charCode == 13
            cmd = @cmd.val()
            @cmd.val ''
            @_text_output "(gdb) "
            @_text_output cmd + '\n', 'text-highlight'
            @gdb.send_cli cmd

    _text_output: (text, cls) ->
        text = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        if cls?
            text = "<span class='#{cls}'>#{text}</span>"
        @console.append text
        @scrolled_window.prop 'scrollTop', @console.height() - @scrolled_window.height()
