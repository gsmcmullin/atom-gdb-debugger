{View, $} = require 'atom-space-pen-views'

module.exports =
class Resizable extends View
    initialize: (@side, size, child) ->
        if side == 'left' or side == 'right'
            @size = @width
            @evkey = 'pageX'
        else
            @size = @height
            @evkey = 'pageY'
        @size size

    @content: (side, intialSize, child) ->
        @div class: 'gdb-resizeable', =>
            @div
                class: "gdb-resize-grip #{side}"
                mousedown: '_resizeStart'
                outlet: 'grip'
            @subview 'child', child

    _resizeStart: (ev) ->
        @_startev = ev
        @initialSize = @size()
        $(document).on 'mousemove', (ev) => @_resize(ev)
        $(document).on 'mouseup', => @_resizeStop()

    _resizeStop: ->
        $(document).off 'mousemove'
        $(document).off 'mouseup'

    _resize: (ev) ->
        #console.log this, ev
        adjust = @_startev[@evkey] - ev[@evkey]
        if @side == 'bottom' or @side == 'right'
            adjust = -adjust
        @size @initialSize + adjust
