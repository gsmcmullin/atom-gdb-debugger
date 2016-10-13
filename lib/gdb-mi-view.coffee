{View} = require 'atom-space-pen-views'

module.exports =
class GdbMiView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @gdb.onGdbmiRaw (data) =>
            @_text_output(data)

    @content: (gdb) ->
        @div class: 'gdb-cli', =>
            @div class: 'scrolled-window', outlet: 'scrolled_window', =>
                @pre outlet: 'console'

    _text_output: (text) ->
        text = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        @console.append(text + '\n')
        @scrolled_window.prop 'scrollTop', @console.height() - @scrolled_window.height()

    getTitle: -> 'GDB/MI'
