{View, $} = require 'atom-space-pen-views'
ConfigView = require './config-view'

module.exports =
class GdbToolbarView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @gdb.onStateChanged (state) =>
            @state.text state
            if state == 'DISCONNECTED'
                @disconnect.hide()
                @connect.show()
            else
                @disconnect.show()
                @connect.hide()

        @gdb.exec.onStateChanged (state) =>
            @target_state.text state

        @gdb.exec.onFrameChanged (frame) =>
            if not frame.addr?
                @frame.text '(no frame)'
                return
            fr_text = "#{frame.addr} in #{frame.func}()"
            if frame.file?
                fr_text += " (#{frame.file}:#{frame.line})"
            @frame.text fr_text

    @content: ->
        @div class: 'btn-toolbar', =>
            @div class: 'btn-group', =>
                @button class: 'btn icon icon-bug', click: 'do_connect', outlet: 'connect'
                @button class: 'btn icon icon-circle-slash', click: 'do_disconnect', outlet: 'disconnect', style: 'display: none'
            @div class: 'btn-group', =>
                @button class: 'btn icon icon-jump-left', click: 'do_start', outlet: 'start'
                @button class: 'btn icon icon-playback-play', click: 'do_continue', outlet: 'continue'
                @button class: 'btn icon icon-playback-pause', click: 'do_interrupt', outlet: 'interrupt'
            @div class: 'btn-group', =>
                @button 'Next', class: 'btn', click: 'do_next', outlet: 'next'
                @button 'Step', class: 'btn', click: 'do_step', outlet: 'step'
                @button 'Finish', class: 'btn', click: 'do_finish', outlet: 'finish'
            @div class: 'btn-group', =>
                @button class: 'btn icon icon-tools', click: 'do_config'

            @div class: 'state-display', =>
                @span '(no frame)', outlet: 'frame'
                @span 'DISCONNECTED', outlet: 'state'
                @span 'EXITED', outlet: 'target_state'

    do_connect: -> @gdb.connect()
    do_disconnect: -> @gdb.disconnect()

    do_start: -> @gdb.exec.start()
    do_continue: -> @gdb.exec.continue()
    do_interrupt: -> @gdb.exec.interrupt()
    do_step: -> @gdb.exec.step()
    do_next: -> @gdb.exec.next()
    do_finish: -> @gdb.exec.finish()

    do_config: ->
        new ConfigView(@gdb)
