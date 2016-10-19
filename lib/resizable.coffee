{View, $} = require 'atom-space-pen-views'

module.exports =
class Resizable extends View
    initialize: (@side, @initialSize, child) ->
        if side == 'left' or side == 'right'
            @width initialSize
        if side == 'top' or side == 'bottom'
            @height initialSize

    @content: (side, intialSize, child) ->
        @div class: 'gdb-resizeable', =>
            @div
                class: "gdb-resize-grip #{side}"
                mousedown: '_resizeStart'
                outlet: 'grip'
            @subview 'child', child

    _resizeStart: (@_startev) ->
        $(document).on 'mousemove', @_resize
        $(document).on 'mouseup', @_resizeStop

    _resizeStop: =>
        $(document).off 'mousemove'
        $(document).off 'mouseup'
        @initialSize = @height()

    _resize: (ev) =>
        switch @side
            when 'top'
                @height @initialSize + @_startev.pageY - ev.pageY
            when 'bottom'
                @height @initialSize - @_startev.pageY + ev.pageY
            when 'left'
                @height @initialSize + @_startev.pageX - ev.pageX
            when 'right'
                @height @initialSize - @_startev.pageX + ev.pageX
