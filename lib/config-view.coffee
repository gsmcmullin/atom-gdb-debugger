{View, $$} = require 'atom-space-pen-views'
{Directory} = require 'atom'

findGDB = ->
    Promise.all (for dirName in process.env.PATH.split(':')
        new Promise (resolve, reject) ->
            new Directory(dirName).getEntries (err, entries) =>
                if err?
                    resolve []
                    return
                resolve(for file in entries
                    if file.getBaseName().search(/^(.*-)?gdb(-.*)?$/) >= 0
                        file.getBaseName()
                )
        )
    .then (ll) ->
        results = []
        for l in ll
            for f in l
                if f? then results.push f
        results

module.exports =
class ConfigView extends View
    initialize: (gdb) ->
        @gdb = gdb
        @panel = atom.workspace.addModalPanel(item: this)
        @panel.show()

        cf = @gdb.config
        @file.val cf.file
        @init.val cf.init
        @dummy.text cf.cmdline
        @isRemote.prop 'checked', cf.isRemote

        findGDB().then (gdbs) =>
            @cmdline.empty()
            for gdb in gdbs
                @cmdline.append $$ -> @option gdb, value: gdb
            @cmdline[0].value = cf.cmdline

    @content: (gdb) ->
        @div =>
            @div class: 'block', =>
                @label "GDB binary:"
                @select class: 'input-text', outlet: 'cmdline', =>
                    # Just so this doesn't sit empty while we wait for promises
                    @option 'gdb', outlet: 'dummy'
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
