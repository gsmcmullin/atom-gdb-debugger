{View} = require 'atom-space-pen-views'
GdbToolbarView = require './gdb-toolbar-view'
GdbCliView = require './gdb-cli-view'

module.exports =
class AtomGdbDebuggerView extends View
    @content: (gdb) ->
        @div class: 'gdb-debugger-panel', =>
            @subview 'toolbar', new GdbToolbarView(gdb)
            @subview 'cli', new GdbCliView(gdb)
