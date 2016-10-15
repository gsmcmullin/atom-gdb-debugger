{View} = require 'atom-space-pen-views'

module.exports =
class ConfigView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @panel = atom.workspace.addModalPanel(item: this)
        @panel.show()

        cf = @gdb.config
        @cmdline.val cf.cmdline
        @file.val cf.file
        @init.val cf.init
        @isRemote.prop 'checked', cf.isRemote

    @content: (gdb) ->
        @div =>
            @div class: 'block', =>
                @label "GDB binary:"
                @input class: 'input-text native-key-bindings', outlet: 'cmdline'
            @div class: 'block', =>
                @label "Target binary:"
                @input class: 'input-text native-key-bindings', outlet: 'file'
            @div class: 'block', =>
                @label class: 'input-label', =>
                    @input class: 'input-checkbox', type: 'checkbox', outlet: 'isRemote'
                    @text 'Target is remote'
            @div class: 'block', =>
                @div "GDB init commands:"
                @textarea class: 'input-textarea native-key-bindings', outlet: 'init'

            @div class: 'block', =>
                @button 'Cancel', class: 'btn inline-block', click: 'do_close'
                @button 'OK', class: 'btn inline-block', click: 'do_ok'

    do_close: ->
        @panel.destroy()

    do_ok: ->
        cf = @gdb.config
        cf.cmdline = @cmdline.val()
        cf.file = @file.val()
        cf.init = @init.val()
        cf.isRemote = @isRemote.prop 'checked'
        @gdb.connect()
        @panel.destroy()
