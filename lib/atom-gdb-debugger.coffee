AtomGdbDebuggerView = require './atom-gdb-debugger-view'
{CompositeDisposable} = require 'atom'
GDB = require './gdb'

module.exports = AtomGdbDebugger =
  atomGdbDebuggerView: null
  panel: null
  subscriptions: null
  gdb: null
  mark: null

  activate: () ->
    @gdb = new GDB('gdb')
    #@gdb.on 'gdbmi-raw', (data) ->
    #    console.log data
    @gdb.on 'frame-changed', (frame) =>
        if @mark? then @mark.destroy()
        @mark = null
        if not frame.fullname? then return
        atom.workspace.open frame.fullname,
                activatePane: false
                initialLine: +frame.line-1
            .then (editor) =>
                @mark = editor.markBufferPosition([+frame.line-1, 1])
                editor.decorateMarker @mark, type: 'line', class: 'gdb-frame'

    @atomGdbDebuggerView = new AtomGdbDebuggerView(@gdb)
    @panel = atom.workspace.addBottomPanel(item: @atomGdbDebuggerView.get(0), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:toggle': => @toggle()

  deactivate: ->
    @panel.destroy()
    @subscriptions.dispose()
    @atomGdbDebuggerView.destroy()

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()
      if @gdb.state == 'DISCONNECTED' then @gdb.connect 'gdb'
