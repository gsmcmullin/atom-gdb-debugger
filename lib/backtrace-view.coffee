{SelectListView, $$} = require 'atom-space-pen-views'

format = ({level, addr, func, file, line}) ->
    fmt = "##{level}  #{addr} in #{func} ()"
    if file?
        fmt += " at #{file}:#{line}"
    return fmt

module.exports =
class BacktraceView extends SelectListView
    initialize: (gdb) ->
        super
        @gdb = gdb
        @gdb.exec.backtrace()
            .then (frames) =>
                @setItems frames
                @panel = atom.workspace.addModalPanel(item: this)
                @panel.show()
                @focusFilterEditor()
            .catch () ->

    getFilterKey: () -> 'func'

    viewForItem: (item) ->
        "<li>#{format(item)}</li>"

    cancel: ->
        @panel.destroy()

    confirmed: (item) ->
        @gdb.exec.selectFrame(item.level)
        @panel.destroy()
