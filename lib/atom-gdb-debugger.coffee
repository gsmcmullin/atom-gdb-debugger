AtomGdbDebuggerView = require './atom-gdb-debugger-view'
GdbMiView = require './gdb-mi-view'
{CompositeDisposable} = require 'atom'
GDB = require './gdb'
fs = require 'fs'
BacktraceView = require './backtrace-view'
ConfigView = require './config-view'

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

module.exports = AtomGdbDebugger =
  atomGdbDebuggerView: null
  panel: null
  subscriptions: null
  gdb: null
  mark: null
  breakMarks: {}

  activate: (state) ->
    @gdb = new GDB(state)
    if state.cmdline?
        @gdb.cmdline = state.cmdline
    @gdb.cwd = atom.project.getPaths()[0]
    @gdb.file = state.file
    @gdb.init = state.init
    if not state.panelVisible?
        state.panelVisible = true

    @atomGdbDebuggerView = new AtomGdbDebuggerView(@gdb)
    @panel = atom.workspace.addBottomPanel
        item: @atomGdbDebuggerView
        visible: state.panelVisible

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add @gdb.exec.onStateChanged ([state, frame]) =>
        if @mark? then @mark.destroy()
        @mark = null
        if not frame? or not frame.fullname? then return
        decorate frame.fullname, frame.line, type: 'line', class: 'gdb-frame'
            .then (mark) => @mark = mark
            .catch () ->

    @subscriptions.add @gdb.breaks.observe (id, bkpt) =>
        if @breakMarks[id]?
            @breakMarks[id].then (mark) =>
                    mark.destroy()
                .catch () ->
            delete @breakMarks[id]
        if not bkpt? or not bkpt.fullname? then return
        @breakMarks[id] = decorate bkpt.fullname, bkpt.line,
                type: 'line-number', class: 'gdb-bkpt'

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:configure': =>
        new ConfigView(@gdb)
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:connect': =>
        if not @gdb.file? or @gdb.file == ''
            new ConfigView(@gdb)
        else
            @gdb.connect()

    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:continue': =>
        @gdb.exec.continue()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:step': =>
        @gdb.exec.step()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:next': =>
        @gdb.exec.next()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:finish': =>
        @gdb.exec.finish()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:interrupt': =>
        @gdb.exec.interrupt()

    @subscriptions.add atom.commands.add 'atom-text-editor', 'atom-gdb-debugger:toggle-breakpoint': (ev) =>
        editor = ev.target.component.editor
        {row} = editor.getCursorBufferPosition()
        file = editor.getBuffer().getPath()
        @gdb.breaks.toggle(file, row+1)

    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:backtrace': =>
        new BacktraceView(@gdb)

    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:toggle-panel': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:open-mi-log': => @mi_log()

  serialize: ->
      cmdline: @gdb.cmdline
      file: @gdb.file
      init: @gdb.init
      panelVisible: @panel.isVisible()

  deactivate: ->
    @gdb.disconnect()
    @panel.destroy()
    @subscriptions.dispose()
    @atomGdbDebuggerView.destroy()

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()

  mi_log: ->
    mi_view = new GdbMiView(@gdb)
    pane = atom.workspace.getActivePane()
    pane.addItem mi_view
    pane.activateItem mi_view
