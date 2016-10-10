AtomGdbDebuggerView = require './atom-gdb-debugger-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomGdbDebugger =
  atomGdbDebuggerView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @atomGdbDebuggerView = new AtomGdbDebuggerView(state.atomGdbDebuggerViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomGdbDebuggerView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-gdb-debugger:toggle': => @toggle()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomGdbDebuggerView.destroy()

  serialize: ->
    atomGdbDebuggerViewState: @atomGdbDebuggerView.serialize()

  toggle: ->
    console.log 'AtomGdbDebugger was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()
