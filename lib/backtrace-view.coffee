{View, $, $$} = require 'atom-space-pen-views'
{formatFrame} = require './utils'

module.exports =
class BacktraceView extends View
    initialize: (@gdb) ->
        @gdb.exec.onStateChanged ([state, frame]) =>
            if state == 'STOPPED'
                @update()
            else
                @empty()

    @content: ->
        @ul id: 'backtrace', class: 'list-tree'

    renderThreads: (threads, selected) ->
        view = $$ ->
            @ul class: 'list-tree', =>
                for thread in threads
                    @li class: 'list-nested-item', 'thread-id': thread.id, =>
                        @div class: 'list-item', =>
                            @span thread['target-id'], class: 'no-icon'
        if selected?
            view.find("li[thread-id=#{selected}]>div").addClass 'selected-row'
        view

    renderFrames: (frames, selected) ->
        view = $$ ->
            @ul class: 'list-tree', =>
                for frame in frames
                    @li class: 'list-nested-item', 'frame-id': frame.level, =>
                        @div class: 'list-item', =>
                            @span formatFrame(frame), class: 'no-icon'
        #@find('div.list-item').on 'dblclick', (ev) => @frameClicked(ev)
        if selected?
            view.find("li[frame-id=#{selected}]>div").addClass 'selected-row'
        view

    renderLocals: (locals) ->
        view = $$ ->
            @ul class: 'list-tree', =>
                for {name, value} in locals
                    @li class: 'list-item', =>
                        @span "#{name} = #{value}", class: 'no-icon'

    update: ->
        @empty()
        @gdb.exec.getThreads()
            .then (results) =>
                @selectedThread = results['current-thread-id']
                @append @renderThreads results.threads, results['current-thread-id']
                @gdb.exec.backtrace @selectedThread
            .then (frames) =>
                @selectedFrame = 0
                @find("li[thread-id=#{@selectedThread}]").append @renderFrames frames, @selectedFrame
                @gdb.exec.getLocals @selectedThread, @selectedFrame
            .then (locals) =>
                @find("li[thread-id=#{@selectedThread}] li[frame-id=#{@selectedFrame}]>div")
                    .after @renderLocals locals

    frameClicked: (ev) ->
        level = ev.currentTarget.getAttribute 'data-id'
        @gdb.exec.selectFrame level
            .then =>
                @level = level
