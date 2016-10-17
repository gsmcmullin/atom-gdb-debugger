{Emitter, Disposable, CompositeDisposable} = require 'atom'

class VarObj
    constructor: (@gdb) ->
        @roots = []
        @vars = {}
        @observers = []
        @watchpoints = {}
        @emitter = new Emitter
        @subscriptions = new CompositeDisposable
        @subscriptions.add @gdb.exec.onStateChanged @_execStateChanged.bind(this)
        @subscriptions.add @gdb.breaks.observe @_breakObserver.bind(this)

    observe: (cb) ->
        # Recursively notify observer of existing items
        r = (n) =>
            v = @vars[n]
            cb n, v
            r(n) for n in v.children or []
        r(n) for n in @roots
        @observers.push cb
        return new Disposable () ->
            @observers.splice(@observers.indexOf(cb), 1)

    add: (expr) ->
        @gdb.send_mi "-var-create - * \"#{expr}\""
            .then (result) =>
                result.exp = expr
                @_added result
            .then (result) =>
                @roots.push result.name
                result

    assign: (name, val) ->
        @gdb.send_mi "-var-assign #{name} #{val}"
            .then ({value}) =>
                @update()
                value

    getExpression: (name) ->
        @gdb.send_mi "-var-info-path-expression #{name}"
            .then ({path_expr}) ->
                path_expr

    evalExpression: (expr) ->
        @gdb.send_mi "-data-evaluate-expression #{expr}"
            .then ({value}) ->
                value

    setWatch: (name) ->
        @getExpression name
            .then (expr) =>
                @gdb.breaks.insertWatch expr
            .then (wp) =>
                v = @vars[name]
                v.watchpoint = wp
                @watchpoints[wp] = name
                @_notifyObservers name, v

    clearWatch: (name) ->
        wp = @vars[name].watchpoint
        @gdb.breaks.remove wp
            .then =>
                v = @vars[name]
                delete v.watchpoint
                delete @watchpoints[wp]
                @_notifyObservers name, v

    _removeVar: (name) ->
        # Remove from roots or parent's children
        if name in @roots
            pc = @roots
        else
            pc = @vars[@vars[name].parent].children
        pc.splice pc.indexOf(name), 1

        # Recursively remove children
        children = @vars[name].children or []
        Promise.all (@_removeVar c for c in children.slice())
            .then =>
                # Remove any watchpoint
                wp = @vars[name].watchpoint
                if wp
                    delete @watchpoints[wp]
                    return @gdb.breaks.remove wp
            .then =>
                # Remove this node
                delete @vars[name]
                @_notifyObservers name

    remove: (name) ->
        @gdb.send_mi "-var-delete #{name}"
            .then =>
                @_removeVar name

    _notifyObservers: (name, v) ->
        cb(name, v) for cb in @observers

    _execStateChanged: ([state]) ->
        if state == 'DISCONNECTED'
            for name in @roots.slice()
                @_removeVar name
            return
        if state != 'STOPPED' then return
        @update()

    update: ->
        @gdb.send_mi "-var-update --all-values *"
            .then ({changelist}) =>
                for v in changelist
                    @vars[v.name].value = v.value
                    @vars[v.name].in_scope = v.in_scope
                    @_notifyObservers v.name, @vars[v.name]

    _addChildren: (name) ->
        @gdb.send_mi "-var-list-children --all-values #{name}"
            .then (result) =>
                Promise.all (@_added(child) for child in result.children.child)

    _added: (result) ->
        @vars[result.name] = result
        if (i = result.name.lastIndexOf '.') >= 0
            result.parent = result.name.slice 0, i
        result.nest = result.name.split('.').length - 1
        @_notifyObservers result.name, result
        if +result.numchild > 0
            return @_addChildren result.name
                .then (children) =>
                    result.children = (child.name for child in children)
                    result
        result

    _breakObserver: (id, bkpt) ->
        if @watchpoints[id]? and not bkpt?
            vo = @vars[@watchpoints[id]]
            delete vo.watchpoint
            delete @watchpoints[id]
            @_notifyObservers vo.name, vo
        if bkpt? and not @watchpoints[id] and bkpt.type.endsWith('watchpoint')
            @add bkpt.what
                .then (v) =>
                    v.watchpoint = bkpt.number
                    @watchpoints[bkpt.number] = v.name
                    @_notifyObservers v.name, v

module.exports = VarObj
