{View, $} = require 'atom-space-pen-views'

module.exports =
class VarWatchView extends View
    initialize: (@gdb) ->
        @gdb.varobj.observe @_varObserver.bind(this)

    @content: (gdb) ->
        @div =>
            @div class: 'block', =>
                @label 'Add expression to watch:'
                @input
                    class: 'input-textarea native-key-bindings'
                    keypress: '_addExpr'
                    outlet: 'expr'
            @div class: 'block', =>
                @ul class: 'list-tree has-collapsable-children', outlet: 'listView'

    getTitle: -> 'Watch Variables'

    _addExpr: (ev) ->
        if ev.charCode != 13 then return
        @gdb.varobj.add @expr.val()
        @expr.val ''

    _itemView: (val) ->
        if +val.numchild == 0
            "<li class='list-item' varobj-name='#{val.name}'>
               #{val.exp} = <span>#{val.value}</span>
             </li>"
        else
            "<li class='list-nested-item' varobj-name='#{val.name}'>
               <div class='list-item'>
                 #{val.exp} = <span>#{val.value}</span>
               </div>
               <ul class='list-tree'></ul>
             </li>"

    _findOrCreate: (val) ->
        item = @find "li[varobj-name='#{val.name}']"
        if item.length != 0
            return item
        parent = @listView
        if val.parent?
            parent = @find "li[varobj-name='#{val.parent}']>ul"
        console.log parent
        item = $ @_itemView val
        console.log item
        parent.append item
        return item

    _varObserver: (id, val) ->
        item = @_findOrCreate val
        item.find('span').text(val.value)
