{View} = require 'atom-space-pen-views'
GdbToolbarView = require './gdb-toolbar-view'
VarWatchView = require './var-watch-view'
BacktraceView = require './backtrace-view'

module.exports =
class DebugPanelView extends View
    @content: (gdb) ->
        @div =>
            @subview 'toolbar', new GdbToolbarView(gdb)
            @subview 'watch', new VarWatchView(gdb)
            @subview 'backtrace', new BacktraceView(gdb)
