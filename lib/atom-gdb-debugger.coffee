AtomGdbDebuggerView = require './atom-gdb-debugger-view'
GdbMiView = require './gdb-mi-view'
{CompositeDisposable} = require 'atom'
GDB = require './gdb'
fs = require 'fs'
BacktraceView = require './backtrace-view'
ConfigView = require './config-view'
VarWatchView = require './var-watch-view'
{cidentFromLine} = require './utils'

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

openInPane = (view) ->
    pane = atom.workspace.getActivePane()
    pane.addItem view
    pane.activateItem view

module.exports = AtomGdbDebugger =
    atomGdbDebuggerView: null
    panel: null
    subscriptions: null
    gdb: null
    mark: null

    activate: (state) ->
        @breakMarks = {}
        @gdb = new GDB(state)
        window.gdb = @gdb
        for k, v of state.gdbConfig
            @gdb.config[k] = v
        @gdb.config.cwd = atom.project.getPaths()[0]
        @panelVisible = state.panelVisible
        @panelVisible ?= true

        @atomGdbDebuggerView = new AtomGdbDebuggerView(@gdb)
        @panel = atom.workspace.addBottomPanel
            item: @atomGdbDebuggerView
            visible: false

        # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
        @subscriptions = new CompositeDisposable

        @subscriptions.add @gdb.exec.onStateChanged ([state, frame]) =>
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

        @subscriptions.add @gdb.breaks.observe (id, bkpt) =>
            if @breakMarks[id]?
                @breakMarks[id].then (mark) =>
                        mark.destroy()
                    .catch () ->
                delete @breakMarks[id]
            if not bkpt? or not bkpt.fullname? then return
            @breakMarks[id] = decorate bkpt.fullname, bkpt.line,
                    type: 'line-number', class: 'gdb-bkpt'

        @subscriptions.add atom.commands.add 'atom-workspace',
            'atom-gdb-debugger:configure': => new ConfigView(@gdb)
            'atom-gdb-debugger:connect': => @connect()
            'atom-gdb-debugger:continue': => @gdb.exec.continue()
            'atom-gdb-debugger:step': => @gdb.exec.step()
            'atom-gdb-debugger:next': => @gdb.exec.next()
            'atom-gdb-debugger:finish': => @gdb.exec.finish()
            'atom-gdb-debugger:interrupt': => @gdb.exec.interrupt()
            'atom-gdb-debugger:backtrace': => new BacktraceView(@gdb)
            'atom-gdb-debugger:toggle-panel': => @toggle()
            'atom-gdb-debugger:open-mi-log': => openInPane new GdbMiView(@gdb)
            'atom-gdb-debugger:watch-variables': => openInPane new VarWatchView(@gdb)

        @subscriptions.add atom.commands.add 'atom-text-editor', 'atom-gdb-debugger:toggle-breakpoint': (ev) =>
            editor = ev.target.component.editor
            {row} = editor.getCursorBufferPosition()
            file = editor.getBuffer().getPath()
            @gdb.breaks.toggle(file, row+1)

        @subscriptions.add atom.workspace.observeTextEditors @hookEditor.bind(this)

    connect: ->
        if @gdb.config.file == ''
            new ConfigView(@gdb)
        else
            @gdb.connect()
                .then =>
                    if @panelVisible
                        @panel.show()
                .catch (err) =>
                    x = atom.notifications.addError 'Error launching GDB',
                        description: err.toString()
                        buttons: [
                            text: 'Reconfigure'
                            onDidClick: =>
                                x.dismiss()
                                new ConfigView(@gdb)
                        ]

    consumeStatusBar: (statusBar) ->
        StatusView = require './status-view'
        @statusBarTile = statusBar.addLeftTile
            item: new StatusView(@gdb)
            priority: 100

    serialize: ->
          gdbConfig: @gdb.config
          panelVisible: @panelVisible

    deactivate: ->
        @statusBarTile?.destroy()
        @statusBarTile = null
        @gdb.disconnect()
        @panel.destroy()
        @subscriptions.dispose()
        @atomGdbDebuggerView.destroy()

    toggle: ->
        if @panel.isVisible()
            @panel.hide()
        else
            @panel.show()
        @panelVisible = @panel.isVisible()

    hookEditor: (ed) ->
        timeout = null
        el = ed.editorElement
        hover = (ev) =>
            screenPosition = el.component.screenPositionForMouseEvent ev
            bufferPosition = ed.bufferPositionForScreenPosition screenPosition
            buffer = ed.getBuffer()
            line = buffer.lineForRow bufferPosition.row
            cident = cidentFromLine line, bufferPosition.column
            if not cident? or cident == '' then return
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
