{View, $} = require 'atom-space-pen-views'

module.exports =
class GdbCliView extends View
    history: []

    initialize: (gdb) ->
        @gdb = gdb
        @gdb.onConsoleOutput ([stream, text]) =>
            switch stream
                when 'LOG' then cls = 'text-error'
                when 'TARGET' then cls = 'text-info'
            @_text_output(text, cls)
        @gdb.exec.onStateChanged ([state]) =>
            if state == 'DISCONNECTED' or state == 'RUNNING'
                @cliDiv.css 'visibility', 'hidden'
            else
                @cliDiv.css 'visibility', 'visible'

    @content: (gdb) ->
        @div class: 'gdb-cli', click: '_focusInput', =>
            @div outlet: 'scrolledContainer', =>
                @pre outlet: 'console'
                @div class: 'gdb-cli-input', outlet: 'cliDiv', =>
                    @pre '(gdb)'
                    @input
                        class: 'native-key-bindings'
                        keydown: '_keyDown'
                        keypress: '_doCli'
                        outlet: 'cmd'

    _focusInput: ->
        @cmd.focus()

    _doCli: (event) ->
        if event.charCode == 13
            delete @histPos
            delete @editHistory
            cmd = @cmd.val()
            @cmd.val ''
            if cmd == ''
                cmd = @history.slice(-1)
            else
                @history.push cmd
            @_text_output "(gdb) "
            @_text_output cmd + '\n', 'text-highlight'
            @gdb.send_cli cmd
                .catch ->

    _text_output: (text, cls) ->
        text = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        if cls?
            text = "<span class='#{cls}'>#{text}</span>"
        @console.append text
        @prop 'scrollTop', @scrolledContainer.height() - @height()

    _keyDown: (ev) ->
        switch ev.keyCode
            when 38 #up
                @_histUp ev
            when 40 #down
                @_histDown ev

    _histUpDown: (ev, f)->
        if @histPos?
            @editHistory[@histPos] = @cmd.val()
        else
            @editHistory = @history.slice()
            @editHistory.push @cmd.val()
            @histPos = @editHistory.length - 1
        f()
        v = @editHistory[@histPos]
        @cmd.val v
        @cmd[0].setSelectionRange(v.length, v.length)
        ev.preventDefault()

    _histUp: (ev) ->
        @_histUpDown ev, => (@histPos-- if @histPos > 0)
    _histDown: (ev) ->
        @_histUpDown ev, => (@histPos++ if @histPos < @history.length)
