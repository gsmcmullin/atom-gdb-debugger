{View} = require 'atom-space-pen-views'
{escapeHTML} = require './utils'
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
        text = escapeHTML(text)
        @console.append(text + '\n')
        @scrolled_window.prop 'scrollTop',
                              @console.height() - @scrolled_window.height()

    getTitle: -> 'GDB/MI'
