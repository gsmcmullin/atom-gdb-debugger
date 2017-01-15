{CompositeDisposable} = require 'atom'
fs = require 'fs'
{cidentFromLine} = require './utils'

posFromMouse = (editor, ev) ->
    screenPosition =
        editor.editorElement.component.screenPositionForMouseEvent ev
    editor.bufferPositionForScreenPosition screenPosition

cidentFromMouse = (ev) ->
    try
        ed = ev.target.model
        {row, column} = posFromMouse ed, ev
        buffer = ed.getBuffer()
        line = buffer.lineForRow row
        cident = cidentFromLine line, column
    catch
        return
    return cident

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

        @subscriptions.add @gdb.exec.onFrameChanged @_frameChanged
        @subscriptions.add @gdb.breaks.observe @_breakpointCreated

        @subscriptions.add atom.commands.add 'atom-text-editor',
            'atom-gdb-debugger:toggle-breakpoint': @_toggleBreakpoint
            'atom-gdb-debugger:context-watch-expression': @_ctxWatchExpr

        @subscriptions.add atom.workspace.observeTextEditors @_hookEditor

        @subscriptions.add atom.contextMenu.add
            'atom-text-editor': [{
                label: "Toggle Breakpoint"
                command: "atom-gdb-debugger:toggle-breakpoint"
                created: (ev) => @ctxEvent = ev
            }, {
                command: "atom-gdb-debugger:context-watch-expression"
                shouldDisplay: (ev) =>
                    @ctxEvent = ev
                    cident = cidentFromMouse ev
                    return cident? and cident != ''
                created: (ev) ->
                    @label = "Watch '#{cidentFromMouse ev}'"
            }]

    _ctxWatchExpr: (ev) =>
        @gdb.vars.add(cidentFromMouse(@ctxEvent))
        .catch (err) ->
            atom.notifications.addError(err.toString())

    _toggleBreakpoint: (ev) =>
        editor = ev.currentTarget.component.editor
        if ev.detail?[0].contextCommand
            {row} = posFromMouse(ev.currentTarget.model, @ctxEvent)
        else
            {row} = editor.getCursorBufferPosition()
        file = editor.getBuffer().getPath()
        @gdb.breaks.toggle(file, row+1)

    _frameChanged: (frame) =>
        if @mark? then @mark.destroy()
        @mark = null
        if not frame? then return
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

    _breakpointCreated: (id, bkpt) ->
        {fullname, line} = bkpt
        if not fullname? then return
        decorate fullname, line,
                type: 'line-number', class: 'gdb-bkpt'
            .then (mark) ->
                bkpt.onChanged ->
                    mark.setBufferRange [[line-1, 0], [line-1, 0]]
                bkpt.onDeleted ->
                    mark.destroy()

    _hookEditor: (ed) =>
        timeout = null
        el = ed.editorElement
        hover = (ev) =>
            try
                cident = cidentFromMouse ev
                if not cident? or cident == '' then return
            catch
                return
            @gdb.vars.evalExpression cident
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
