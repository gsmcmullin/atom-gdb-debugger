{View, $$} = require 'atom-space-pen-views'

class BreakView extends View
    initialize: (@bkpt) ->
        @bkpt.onDeleted => @remove()
        @bkpt.onChanged => @update()
        @update()

    @content: ->
        @tr =>
            @td class: 'expand-column', =>
                @span outlet: 'what'
                @span ' '
                @span '0', outlet: 'times', class: 'badge'
            @td style: 'width: 100%'
            @td click: '_remove', =>
                @span class: 'delete'

    update: ->
        {func, file, line, times} = @bkpt
        @what.text "in #{func} () at #{file}:#{line}"
        if @times.text() != times
            @times.addClass 'badge-info'
        @times.text times

    _remove: ->
        @bkpt.remove()

module.exports =
class BreakListView extends View
    initialize: (@gdb) ->
        @gdb.breaks.observe @breakpointObserver.bind(this)
        @gdb.exec.onStateChanged @_execStateChanged.bind(this)

    @content: ->
        @table id: 'break-list', class: 'list-tree', =>

    breakpointObserver: (id, bkpt) ->
        # Don't show watchpoints in here
        if not bkpt.type.endsWith 'breakpoint'
            return
        @append new BreakView bkpt

    _execStateChanged: ([state, frame]) ->
        if state == 'RUNNING'
            v = @find('.badge-info')
            v.removeClass 'badge-info'
