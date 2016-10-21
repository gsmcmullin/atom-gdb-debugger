{View, $} = require 'atom-space-pen-views'

class VarItemView extends View
    initialize: (@gdb, item) ->
        @name = item.name
        if +item.numchild != 0
            @find('input#value').attr('disabled', true)
        if item.watchpoint?
            @find('input#wp-toggle').prop('checked', true)

    @content: (gdb, item) ->
        @tr name: item.name, parent: item.parent, =>
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
        @gdb.varobj.remove @name

    _toggleWP: (ev) ->
        if ev.target.checked
            @gdb.varobj.setWatch @name
                .catch (err) =>
                    atom.notifications.addError err.toString()
                    ev.target.checked = false
        else
            @gdb.varobj.clearWatch @name
                .catch (err) =>
                    atom.notifications.addError err.toString()
                    ev.target.checked = true

    toggleCollapse: ->
        if @hasClass 'collapsable'
            @toggleClass 'collapsed'
            if @hasClass 'collapsed'
                @_hideTree @name
            else
                @_showTree @name

    _valueFocus: (ev) ->
        ev.target.oldValue = ev.target.value
        ev.target.select()
    _valueBlur: (ev) ->
        ev.target.value = ev.target.oldValue
    _valueKeydown: (ev) ->
        switch ev.keyCode
            when 13 # Enter
                @gdb.varobj.assign @name, ev.target.value
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
        @gdb.varobj.observe @_varObserver.bind(this)
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
        @gdb.varobj.add @expr.val()
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

    _addItem: (id, val) ->
        view = @varviews[id] = new VarItemView(@gdb, val)
        if not val.parent?
            @table.append view
        else
            lastName = @_findLast val.parent
            view.insertAfter @varviews[lastName]
        view

    _varObserver: (id, val) ->
        view = @varviews[id]
        if not val?
            view.remove()
            delete @varviews[id]
            return
        if not view?
            view = @_addItem id, val
        v = view.find('input#value')
        if v.val() != val.value
            v.val val.value
            v.addClass 'changed'
            while id = @gdb.varobj.vars[id].parent
                @varviews[id].find('input#value').addClass 'changed'
        wp = view.find('input#wp-toggle')
        wp.prop 'checked', val.watchpoint?
        badge = view.find('.badge')
        if val.times?
            badge.show()
            if val.times != badge.text()
                badge.addClass 'badge-info'
            badge.text val.times
        else
            badge.text '0'
            badge.hide()
        if +val.numchild > 0
            view.addClass('collapsable')

    _execStateChanged: ([state, frame]) ->
        if state == 'RUNNING'
            @find('.changed').removeClass 'changed'
            @find('.badge-info').removeClass('badge-info')
