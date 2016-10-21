{View, $$} = require 'atom-space-pen-views'

class BreakView extends View
    initialize: (@gdb, @id) ->

    @content: ->
        @tr =>
            @td class: 'expand-column', =>
                @span outlet: 'what'
                @span ' '
                @span '0', outlet: 'times', class: 'badge'
            @td style: 'width: 100%'
            @td click: '_remove', =>
                @span class: 'delete'

    update: ({func, file, line, times}) ->
        @what.text "in #{func} () at #{file}:#{line}"
        if @times.text() != times
            @times.addClass 'badge-info'
        @times.text times

    _remove: ->
        @gdb.breaks.remove @id

module.exports =
class BreakListView extends View
    initialize: (@gdb) ->
        @gdb.breaks.observe @breakpointObserver.bind(this)
        @gdb.exec.onStateChanged @_execStateChanged.bind(this)
        @items = {}

    @content: ->
        @table id: 'break-list', class: 'list-tree', =>

    findOrCreate: (id) ->
        if @items[id]?
            return @items[id]
        view = @items[id] = new BreakView @gdb, id
        @append view
        return view

    breakpointObserver: (id, bkpt) ->
        if not bkpt?
            # Remove deleted breakpoints
            if @items[id]?
                @items[id].remove()
                delete @items[id]
            return
        # Don't show watchpoints in here
        if not bkpt.type.endsWith 'breakpoint'
            return
        view = @findOrCreate(id)
        view.update bkpt

    _execStateChanged: ([state, frame]) ->
        if state == 'RUNNING'
            v = @find('.badge-info')
            v.removeClass 'badge-info'
