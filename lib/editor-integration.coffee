{CompositeDisposable} = require 'atom'
fs = require 'fs'
{cidentFromLine} = require './utils'

posFromMouse = (editor, ev) ->
    screenPosition = editor.editorElement.component.screenPositionForMouseEvent ev
    editor.bufferPositionForScreenPosition screenPosition

decorate = (file, line, decoration) ->
    line = +line-1
    new Promise (resolve, reject) ->
            fs.access file, fs.R_OK, (err) ->
                if err then reject(err) else resolve()
        .then () ->
            atom.workspace.open file,
                activatePane: false
                initialLine: line
                searchAllPanes: true
                pending: true
        .then (editor) ->
            mark = editor.markBufferPosition([line, 1])
            editor.decorateMarker mark, decoration
            mark

module.exports =
class EditorIntegration
    constructor: (@gdb) ->
        @breakMarks = {}

        @subscriptions = new CompositeDisposable

        @subscriptions.add @gdb.exec.onStateChanged @_execStateChanged
        @subscriptions.add @gdb.breaks.observe @_breakpointChanged

        @subscriptions.add atom.commands.add 'atom-text-editor',
            'atom-gdb-debugger:toggle-breakpoint': @_toggleBreakpoint

        @subscriptions.add atom.workspace.observeTextEditors @_hookEditor

    _toggleBreakpoint: (ev) =>
        editor = ev.target.component.editor
        {row} = editor.getCursorBufferPosition()
        file = editor.getBuffer().getPath()
        @gdb.breaks.toggle(file, row+1)

    _execStateChanged: ([state, frame]) =>
        if @mark? then @mark.destroy()
        @mark = null
        if state != 'STOPPED' or not frame? then return
        if not frame.fullname?
            atom.notifications.addWarning "Debug info not available",
                description: "This may be because the function is part of an
                external library, or the binary was compiled without debug
                information."
            return
        decorate frame.fullname, frame.line, type: 'line', class: 'gdb-frame'
            .then (mark) => @mark = mark
            .catch () ->
                atom.notifications.addWarning "Source file not available",
                    description: "Unable to open `#{frame.file}` for the
                    current frame.  This may be because the function is part
                    of a external included library."

    _breakpointChanged: (id, bkpt) =>
        if @breakMarks[id]?
            @breakMarks[id].then (mark) =>
                    mark.destroy()
                .catch () ->
            delete @breakMarks[id]
        if not bkpt? or not bkpt.fullname? then return
        @breakMarks[id] = decorate bkpt.fullname, bkpt.line,
                type: 'line-number', class: 'gdb-bkpt'

    _hookEditor: (ed) =>
        timeout = null
        el = ed.editorElement
        hover = (ev) =>
            try
                {row, column} = posFromMouse ed, ev
                buffer = ed.getBuffer()
                line = buffer.lineForRow row
                cident = cidentFromLine line, column
                if not cident? or cident == '' then return
            catch
                return
            @gdb.varobj.evalExpression cident
                .then (val) ->
                    atom.notifications.addInfo "`#{cident} = #{val}`"
                .catch () ->

        el.addEventListener 'mousemove', (ev) ->
            if timeout?
                clearTimeout timeout
            timeout = setTimeout hover.bind(null, ev), 2000
        el.addEventListener 'mouseout', () ->
            clearTimeout timeout
            timeout = null
