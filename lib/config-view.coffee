{View, TextEditorView} = require 'atom-space-pen-views'

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
            @div "GDB binary:"
            @input class: 'input-text native-key-bindings', outlet: 'cmdline'
            #@subview 'cmdline', new TextEditorView(mini: true)
            @div "Target binary:"
            @input class: 'input-text native-key-bindings', outlet: 'file'
            #@subview 'file', new TextEditorView(mini: true)
            @div "GDB init commands:"
            @textarea class: 'input-textarea native-key-bindings', outlet: 'init'

            #@subview 'init', new TextEditorView()
            @button 'Cancel', class: 'btn', click: 'do_close'
            @button 'OK', class: 'btn', click: 'do_ok'

    do_close: ->
        @panel.destroy()
        #atom.workspace.panelForItem(this.get(0)).hide()

    do_ok: ->
        @gdb.cmdline = @cmdline.val()
        @gdb.file = @file.val()
        @gdb.init = @init.val()
        @panel.destroy()
