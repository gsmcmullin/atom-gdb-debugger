{View, $, $$} = require 'atom-space-pen-views'
{formatFrame} = require './utils'

module.exports =
class BacktraceView extends View
    initialize: (@gdb) ->
        @gdb.exec.onStateChanged ([state, frame]) =>
            if state == 'STOPPED'
                @level = 0
                @update()
            else
                @empty()

    @content: ->
        @ul id: 'backtrace', class: 'list-tree'

    render: (frames) ->
        @empty()
        for frame in frames
            @append $$ ->
                @li class: 'list-item', 'data-id': frame.level, =>
                    @span formatFrame(frame), class: 'no-icon'
        @find('li').on 'dblclick', (ev) => @frameClicked(ev)
        @find("li[data-id=#{@level}]").addClass 'selected-frame'

    update: ->
        @gdb.exec.backtrace()
            .then @render.bind(this)

    frameClicked: (ev) ->
        console.log ev
        level = ev.currentTarget.getAttribute 'data-id'
        @gdb.exec.selectFrame level
            .then =>
                @level = level
