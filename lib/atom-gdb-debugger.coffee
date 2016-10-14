AtomGdbDebuggerView = require './atom-gdb-debugger-view'
GdbMiView = require './gdb-mi-view'
{CompositeDisposable} = require 'atom'
GDB = require './gdb'
fs = require 'fs'

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

    @atomGdbDebuggerView = new AtomGdbDebuggerView(@gdb)
    @panel = atom.workspace.addBottomPanel(item: @atomGdbDebuggerView.get(0), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    @subscriptions.add @gdb.exec.onFrameChanged (frame) =>
        if @mark? then @mark.destroy()
        @mark = null
        if not frame.fullname? then return
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
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:mi-log': => @mi_log()

  serialize: ->
      cmdline: @gdb.cmdline
      file: @gdb.file
      init: @gdb.init

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
      if @gdb.state == 'DISCONNECTED' then @gdb.connect 'gdb'

  mi_log: ->
    mi_view = new GdbMiView(@gdb)
    pane = atom.workspace.getActivePane()
    pane.addItem mi_view
    pane.activateItem mi_view
