{View, $} = require 'atom-space-pen-views'

class VarItemView extends View
    initialize: (@gdb, @item) ->
        @item.onChanged => @_updated()
        @item.onDeleted => @_deleted()
        @_updated()

    _updated: ->
        if +@item.numchild != 0
            @find('input#value').attr('disabled', true)
            @addClass('collapsable')
            if not @item.children?
                @addClass('collapsed')
        if @item.watchpoint?
            @find('input#wp-toggle').prop('checked', true)

        v = @find('input#value')
        if v.val() != @item.value
            v.val @item.value
            v.addClass 'changed'

        wp = @find('input#wp-toggle')
        wp.prop 'checked', @item.watchpoint?
        badge = @find('.badge')
        if @item.watchpoint?
            badge.show()
            if @item.watchpoint.times != badge.text()
                badge.addClass 'badge-info'
            badge.text @item.watchpoint.times
        else
            badge.text '0'
            badge.hide()

    _deleted: ->
        @remove()

    @content: (gdb, item) ->
        @tr name: item.name, parent: item.parent?.name, =>
            @td class: 'expand-column', click: 'toggleCollapse', =>
                @span item.exp,
                    style: "margin-left: #{item.nest}em"
                @span ' '
                @span '0', class: 'badge'
            if +item.numchild == 0
                @td =>
                    @input
                        id: 'wp-toggle'
                        class: 'input-toggle'
                        type: 'checkbox'
                        click: '_toggleWP'
            else
                @td()
            @td style: 'width: 100%', =>
                @input
                    id: 'value'
                    class: 'input-text native-key-bindings'
                    value: item.value
                    focus: '_valueFocus'
                    blur: '_valueBlur'
                    keydown: '_valueKeydown'
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
        @item.remove()

    _toggleWP: (ev) ->
        if ev.target.checked
            @item.setWatch()
                .catch (err) =>
                    atom.notifications.addError err.toString()
                    ev.target.checked = false
        else
            @item.clearWatch()
                .catch (err) =>
                    atom.notifications.addError err.toString()
                    ev.target.checked = true

    toggleCollapse: ->
        if @hasClass 'collapsable'
            @toggleClass 'collapsed'
            if @hasClass 'collapsed'
                @_hideTree @item.name
            else
                if not @item.children?
                    @item.addChildren()
                @_showTree @item.name

    _valueFocus: (ev) ->
        ev.target.oldValue = ev.target.value
        ev.target.select()
    _valueBlur: (ev) ->
        ev.target.value = ev.target.oldValue
    _valueKeydown: (ev) ->
        switch ev.keyCode
            when 13 # Enter
                @item.assign ev.target.value
                    .then (val) ->
                        ev.target.oldValue = ev.target.value = val
                        ev.target.blur()
                    .catch (err) ->
                        ev.target.blur()
                        atom.notifications.addError err.toString()
            when 27 # Escape
                ev.target.blur()

module.exports =
class VarWatchView extends View
    initialize: (@gdb) ->
        @varviews = {}
        @gdb.vars.observe @_addItem.bind(this)
        @gdb.exec.onStateChanged @_execStateChanged.bind(this)

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
                @div class: 'var-watch-tree', =>
                    @table outlet: 'table', =>
                        @tr =>
                            @th 'Expression'
                            @th 'WP', style: 'text-align: center'
                            @th 'Value'

    getTitle: -> 'Watch Variables'

    _addExpr: (ev) ->
        if ev.charCode != 13 then return
        @gdb.vars.add @expr.val()
            .then =>
                @error.text ''
            .catch (err) =>
                @error.text err
        @expr.val ''

    _findLast: (name) ->
        children = @find("tr[parent='#{name}']")
        if children.length
            nextName = children[children.length-1].getAttribute('name')
            return @_findLast nextName
        return name

    _addItem: (val) ->
        view = new VarItemView(@gdb, val)
        if not val.parent?
            @table.append view
        else
            lastName = @_findLast val.parent.name
            last = @find("tr[name='#{lastName}']")
            view.insertAfter last
        view

    _execStateChanged: ([state, frame]) ->
        if state == 'RUNNING'
            @find('.changed').removeClass 'changed'
            @find('.badge-info').removeClass('badge-info')
