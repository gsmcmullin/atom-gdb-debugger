{View, $} = require 'atom-space-pen-views'

class VarItemView extends View
    initialize: (@gdb, {@name}) ->

    @content: (gdb, item) ->
        if item.numchild > 0 then cls = 'collapsable'
        @tr name: item.name, parent: item.parent, class: cls, =>
            @td class: 'expand-column', click: 'toggleCollapse', =>
                @span item.exp,
                    style: "margin-left: #{item.nest}em"
            if +item.numchild == 0
                @td =>
                    @input
                        class: 'input-toggle'
                        type: 'checkbox'
                        click: '_toggleWP'
            else
                @td()
            @td item.value, id: 'value'
            @td click: '_remove', =>
                @span class: 'delete'

    _hideTree: (id) ->
        children = $(this).parent().find("tr[parent='#{id}']")
        children.hide()
        for child in children
            @_hideTree child.getAttribute('name')

    _showTree: (id) ->
        children = $(this).parent().find("tr[parent='#{id}']")
        children.show()
        for child in children
            $child = $(child)
            if not $child.hasClass 'collapsed'
                @_showTree $child.attr 'name'

    _remove: ->
        @gdb.varobj.remove @name

    _toggleWP: (ev) ->
        if ev.target.checked
            @gdb.varobj.getExpression @name
                .then (expr) =>
                    @gdb.breaks.insertWatch expr
                .then (wp) =>
                    @wp = wp
                .catch (err) =>
                    atom.notifications.addError(err)
                    ev.target.checked = false
        else
            @gdb.breaks.remove @wp
                .then ->
                    delete @wp
                .catch (err) =>
                    atom.notifications.addError(err)
                    ev.target.checked = true

    toggleCollapse: ->
        if @hasClass 'collapsable'
            @toggleClass 'collapsed'
            if @hasClass 'collapsed'
                @_hideTree @name
            else
                @_showTree @name

module.exports =
class VarWatchView extends View
    items: {}

    initialize: (@gdb) ->
        @gdb.varobj.observe @_varObserver.bind(this)

    @content: (gdb) ->
        @div class: 'var-watch-view', =>
            @div class: 'block', =>
                @label 'Add expression to watch:'
                @input
                    class: 'input-textarea native-key-bindings'
                    keypress: '_addExpr'
                    outlet: 'expr'
            @div class: 'block', =>
                @div class: 'error-message', outlet: 'error'
            @div class: 'block', =>
                @div class: 'tree-view', =>
                    @table outlet: 'table', =>
                        @tr =>
                            @th 'Expression'
                            @th 'WP', style: 'text-align: center'
                            @th 'Value'

    getTitle: -> 'Watch Variables'

    _addExpr: (ev) ->
        if ev.charCode != 13 then return
        @gdb.varobj.add @expr.val()
            .then =>
                @error.text ''
            .catch (err) =>
                @error.text err
        @expr.val ''

    _addItem: (id, val) ->
        view = @items[id] = new VarItemView(@gdb, val)
        if not val.parent?
            return @table.append view
        prev = @find "tr[parent='#{val.parent}']"
        if prev.length
            return view.insertAfter(prev[prev.length-1])
        view.insertAfter(@items[val.parent])

    _varObserver: (id, val) ->
        view = @items[id]
        if not view? and val?
            return @_addItem id, val
        if not val?
            view.remove()
            delete @items[id]
            return
        view.find('#value').text(val.value)
