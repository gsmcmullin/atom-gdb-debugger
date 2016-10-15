{Emitter, Disposable, CompositeDisposable} = require 'atom'

class VarObj
    varno: 0
    roots: []
    vars: {}
    observers: []

    constructor: (@gdb) ->
        @emitter = new Emitter
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.exec.onStateChanged @_update.bind(this)

    observe: (cb) ->
        @observers.push cb
        return new Disposable () ->
            @observers.splice(@observers.indexOf(cb), 1)

    add: (expr) ->
        name = "var#{@varno}"
        @varno += 1
        @gdb.send_mi "-var-create #{name} * \"#{expr}\""
            .then (result) => @_added result
            .then (result) =>
                @roots.push result.name
                result

    _notifyObservers: (v) ->
        cb(v.name, v) for cb in @observers

    _update: ([state]) ->
        if state != 'STOPPED' then return
        @gdb.send_mi "-var-update --all-values *"
            .then ({changelist}) =>
                for v in changelist
                    @vars[v.name].value = v.value
                    @vars[v.name].in_scope = v.in_scope
                    @_notifyObservers @vars[v.name]

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
                    @_notifyObservers result
                    result
        else
            @_notifyObservers result
            result

module.exports = VarObj
