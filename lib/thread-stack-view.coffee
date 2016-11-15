{View, $, $$} = require 'atom-space-pen-views'
{formatFrame} = require './utils'

module.exports =
class ThreadStackView extends View
    initialize: (@gdb) ->
        @gdb.exec.onStateChanged ([state, frame]) =>
            if state == 'STOPPED'
                @update()
            else
                @empty()

    @content: ->
        @div id: 'backtrace'

    renderThreads: (threads, selected) ->
        view = $$ ->
            @ul class: 'list-tree has-collapsable-children', =>
                for thread in threads
                    @li class: 'list-nested-item collapsed', 'thread-id': thread.id, =>
                        @div class: 'list-item', =>
                            @span thread['target-id']
        if selected?
            view.find("li[thread-id=#{selected}]").addClass 'selected'
        view.find("li>div").on 'click', (ev) =>
            li = $(ev.currentTarget).parent()
            li.toggleClass 'collapsed'
            if not li.hasClass('collapsed') and li.find('ul').length == 0
                thread = li.attr 'thread-id'
                @gdb.exec.getFrames thread
                    .then (frames) =>
                        li.append @renderFrames frames
        view

    renderFrames: (frames, selected) ->
        view = $$ ->
            @ul class: 'list-tree', =>
                for frame in frames
                    @li class: 'list-nested-item collapsed', 'frame-id': frame.level, =>
                        @div class: 'list-item', =>
                            @span formatFrame(frame)
        if selected?
            view.find("li[frame-id=#{selected}]").addClass 'selected'
        view.find("li>div").on 'click', (ev) =>
            li = $(ev.currentTarget).parent()
            li.toggleClass 'collapsed'
            if not li.hasClass('collapsed') and li.find('ul').length == 0
                thread = li.parent().closest('li').attr 'thread-id'
                frame = li.attr 'frame-id'
                @gdb.exec.getLocals frame, thread
                    .then (locals) =>
                        li.append @renderLocals locals
        view

    renderLocals: (locals) ->
        view = $$ ->
            @ul class: 'list-tree', =>
                for {name, value} in locals
                    @li class: 'list-item locals', 'data-name': name, =>
                        @span "#{name} = #{value}"
        view.find('li').on 'dblclick', (ev) =>
            li = $(ev.currentTarget)
            exp = li.attr 'data-name'
            li = li.parent().closest('li')
            frame = li.attr 'frame-id'
            li = li.parent().closest('li')
            thread = li.attr 'thread-id'
            @gdb.vars.add exp, frame, thread
        view

    update: ->
        @empty()
        @gdb.exec.getThreads()
            .then (threads) =>
                @selectedThread ?= threads[0].id
                @append @renderThreads threads, @selectedThread
                @gdb.exec.getFrames @selectedThread
            .then (frames) =>
                @selectedFrame = 0
                @find("li[thread-id=#{@selectedThread}]")
                    .removeClass 'collapsed'
                    .append @renderFrames frames, @selectedFrame
                @gdb.exec.getLocals @selectedFrame, @selectedThread
            .then (locals) =>
                @find("li[thread-id=#{@selectedThread}] li[frame-id=#{@selectedFrame}]")
                    .removeClass 'collapsed'
                    .append @renderLocals locals

    frameClicked: (ev) ->
        level = ev.currentTarget.getAttribute 'data-id'
        @gdb.exec.selectFrame level
            .then =>
                @level = level
