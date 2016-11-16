{View} = require 'atom-space-pen-views'
GdbToolbarView = require './gdb-toolbar-view'
VarWatchView = require './var-watch-view'
ThreadStackView = require './thread-stack-view'
BreakListView = require './break-list-view'

class SubPanel extends View
    @content: (header, child)->
        @div class: 'debug-subpanel', =>
            @div header, class: 'header', click: 'toggleChild', outlet: 'header'
            @subview 'child', -> child

    toggleChild: ->
        if @child().css('display') == 'none'
            @child().show()
            @header.removeClass 'collapsed'
        else
            @child().hide()
            @header.addClass 'collapsed'

module.exports =
class DebugPanelView extends View
    @content: (gdb) ->
        @div =>
            @subview 'toolbar', new GdbToolbarView(gdb)
            @subview 'watch', new SubPanel 'Watch Variables', new VarWatchView(gdb)
            @subview 'breakpoints', new SubPanel 'Breakpoints', new BreakListView(gdb)
            @subview 'stacks', new SubPanel 'Call Stacks', new ThreadStackView(gdb)
