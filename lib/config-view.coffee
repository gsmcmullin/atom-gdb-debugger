{View} = require 'atom-space-pen-views'

module.exports =
class ConfigView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @panel = atom.workspace.addModalPanel(item: this)
        @panel.show()

        @cmdline.val @gdb.cmdline
        @file.val @gdb.file
        @init.val @gdb.init

    @content: (gdb) ->
        @div =>
            @div class: 'block', =>
                @label "GDB binary:"
                @input class: 'input-text native-key-bindings', outlet: 'cmdline'
            @div class: 'block', =>
                @label "Target binary:"
                @input class: 'input-text native-key-bindings', outlet: 'file'
            @div class: 'block', =>
                @div "GDB init commands:"
                @textarea class: 'input-textarea native-key-bindings', outlet: 'init'

            @div class: 'block', =>
                @button 'Cancel', class: 'btn inline-block', click: 'do_close'
                @button 'OK', class: 'btn inline-block', click: 'do_ok'

    do_close: ->
        @panel.destroy()

    do_ok: ->
        @gdb.cmdline = @cmdline.val()
        @gdb.file = @file.val()
        @gdb.init = @init.val()
        @panel.destroy()
