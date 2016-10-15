{View} = require 'atom-space-pen-views'
{formatFrame} = require './utils'

module.exports =
class StatusView extends View
    initialize: (@gdb) ->
        @gdb.exec.onStateChanged @_onStateChanged.bind(this)
        @_onStateChanged [@gdb.exec.state]

    @content: ->
        @span 'UNKNOWN', class: 'text-error'

    _onStateChanged: ([state, frame]) ->
        switch state
            when 'DISCONNECTED' then cls = 'text-error'
            when 'EXITED' then cls = 'text-warning'
            when 'STOPPED' then cls = 'text-info'
            when 'RUNNING' then cls = 'text-success'

        @removeClass()
        if frame?
            @text formatFrame(frame)
        else
            @text state
        @addClass cls
