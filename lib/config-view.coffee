{View, $$} = require 'atom-space-pen-views'
{Directory, File} = require 'atom'
remote = require 'remote'
{dialog} = require('electron').remote

findGDB = ->
    pathsep = if process.platform == 'win32' then ';' else ':'
    Promise.all (for dirName in process.env.PATH.split(pathsep)
        new Promise (resolve, reject) ->
            new Directory(dirName).getEntries (err, entries) ->
                if err?
                    resolve []
                    return
                resolve(for file in entries
                    if file.getBaseName().search(/^(.*-)?gdb(-.*)?(\..*)?$/) >= 0
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
    initialize: (@config) ->
        @panel = atom.workspace.addModalPanel(item: this)
        @panel.show()

        @_setFile @config.file
        @init.val @config.init
        @dummy.text @config.cmdline

        @cmdline.on 'change', => @_validate()

        findGDB().then (gdbs) =>
            if gdbs.length == 0
                @dummy.text 'No GDB found'
                @cmdline.addClass 'error'
                @_validate()
                return
            @cmdline.empty()
            for gdb in gdbs
                @cmdline.append $$ -> @option gdb, value: gdb
            @cmdline[0].value = @config.cmdline
            @_validate()

    @content: (gdb) ->
        @div class: 'gdb-config-view', =>
            @div class: 'block', =>
                @label "GDB binary:"
                @select class: 'input-text', outlet: 'cmdline', =>
                    # Just so this doesn't sit empty while we wait for promises
                    @option 'gdb', value: '', outlet: 'dummy'
            @div class: 'block', =>
                @label "Target binary:"
                @div style: 'display: flex', click: '_selectBinary', =>
                    @button 'Browse', class: 'btn'
                    @input
                        value: 'No file selected'
                        style: 'flex: 1'
                        class: 'input-text native-key-bindings error'
                        disabled: true
                        outlet: 'fileDisplay'
            @div class: 'block', =>
                @div "GDB init commands:"
                @textarea class: 'input-textarea native-key-bindings', outlet: 'init'

            @div class: 'block', =>
                @button 'Cancel', class: 'btn inline-block', click: 'do_close'
                @button 'OK',
                    class: 'btn inline-block'
                    disabled: true
                    outlet: 'ok'
                    click: 'do_ok'

    do_close: ->
        @panel.destroy()

    do_ok: ->
        @config.cmdline = @cmdline.val()
        @config.file = @file
        @config.init = @init.val()
        @panel.destroy()
        atom.commands.dispatch atom.views.getView(atom.workspace), 'atom-gdb-debugger:connect'

    _setFile: (path) ->
        if not path? or path == ''
            delete @file
            @fileDisplay.val 'No file selected'
            return
        f = new File path, false
        @fileDisplay.val f.getBaseName()
        f.exists().then (exists) =>
            if not exists
                @fileDisplay.addClass 'error'
                delete @file
            else
                @fileDisplay.removeClass 'error'
                @file = path
            @_validate()

    _selectBinary: ->
        dialog.showOpenDialog {
            title: 'Select target binary'
            defaultPath: @config.cwd
            properties :['openFile']
        }, (file) =>
            if not file? then return
            @_setFile file[0]

    _validate: ->
        if @file? and @cmdline.val() != ''
            @ok.attr 'disabled', false
            return false
        else
            @ok.attr 'disabled', true
            return true
