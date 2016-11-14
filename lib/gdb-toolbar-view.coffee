{View, $} = require 'atom-space-pen-views'
ConfigView = require './config-view'

module.exports =
class GdbToolbarView extends View
    @cmdMask:
        'DISCONNECTED': ['connect', 'configure']
        'EXITED': ['connect', 'configure', 'continue']
        'STOPPED': ['connect', 'configure', 'continue', 'next', 'step', 'finish']
        'RUNNING': ['connect', 'configure', 'interrupt']

    initialize: (gdb) ->
        @gdb = gdb
        @gdb.exec.onStateChanged @_onStateChanged.bind(this)
        for button in @find('button')
            cmd = button.getAttribute 'command'
            this[cmd] = $(button)
            if cmd == 'connect' then continue
            button.addEventListener 'click', @do

    @content: ->
        @div class: 'btn-toolbar', =>
            @div class: 'btn-group', =>
                @button class: 'btn icon icon-plug', command: 'connect', click: 'toggleConnect'
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

    toggleConnect: ->
        if @connect.hasClass 'selected'
            atom.commands.dispatch atom.views.getView(atom.workspace), "atom-gdb-debugger:disconnect"
        else
            atom.commands.dispatch atom.views.getView(atom.workspace), "atom-gdb-debugger:connect"

    _onStateChanged: ([state, frame]) ->
        if state == 'DISCONNECTED'
            @connect.removeClass 'selected'
        else
            @connect.addClass 'selected'

        enabledCmds = GdbToolbarView.cmdMask[state]
        for button in @find('button')
            if button.getAttribute('command') in enabledCmds
                button.removeAttribute 'disabled'
            else
                button.setAttribute 'disabled', true
