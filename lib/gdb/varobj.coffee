{Emitter, Disposable, CompositeDisposable} = require 'atom'

class VarObj
    varno: 0
    roots: []
    vars: {}

    constructor: (@gdb) ->
        @emitter = new Emitter
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.exec.onStateChanged @_update.bind(this)

    add: (expr) ->
        name = "var#{@varno}"
        @varno += 1
        @gdb.send_mi "-var-create #{name} * \"#{expr}\""
            .then (result) => @_added result
            .then (result) =>
                @roots.push result.name
                result

    _update: ([state]) ->
        if state != 'STOPPED' then return
        @gdb.send_mi "-var-update --all-values *"
            .then ({changelist}) =>
                for v in changelist
                    @vars[v.name].value = v.value
                    @vars[v.name].in_scope = v.in_scope

    _addChildren: (name) ->
        @gdb.send_mi "-var-list-children --all-values #{name}"
            .then (result) =>
                Promise.all (@_added(child) for child in result.children.child)

    _added: (result) ->
        @vars[result.name] = result
        if (i = result.name.lastIndexOf '.') >= 0
            result.parent = result.name.slice 0, i
        if +result.numchild > 0
            @_addChildren result.name
                .then (children) =>
                    result.children = (child.name for child in children)
                    result
        else
            Promise.resolve result

module.exports = VarObj
