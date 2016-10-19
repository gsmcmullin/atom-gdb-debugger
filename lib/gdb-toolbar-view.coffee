{View, $} = require 'atom-space-pen-views'
ConfigView = require './config-view'

module.exports =
class GdbToolbarView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @gdb.exec.onStateChanged @_onStateChanged.bind(this)
        for button in @find('button')
            this[button.getAttribute 'command'] = $(button)
            button.addEventListener 'click', @do

    @content: ->
        @div class: 'btn-toolbar', =>
            @div class: 'btn-group', =>
                @button class: 'btn icon icon-plug', command: 'connect'
                @button class: 'btn icon icon-tools', command: 'configure'
            @div class: 'btn-group', =>
                @button class: 'btn icon icon-playback-play', command: 'continue'
                @button class: 'btn icon icon-playback-pause', command: 'interrupt'
            @div class: 'btn-group', =>
                @button 'Next', class: 'btn', command: 'next'
                @button 'Step', class: 'btn', command: 'step'
                @button 'Finish', class: 'btn', command: 'finish'

    do: (ev) ->
        command = ev.target.getAttribute 'command'
        atom.commands.dispatch atom.views.getView(atom.workspace), "atom-gdb-debugger:#{command}"

    _onStateChanged: ([state, frame]) ->
        if state == 'DISCONNECTED'
            @connect.removeClass 'selected'
        else
            @connect.addClass 'selected'
