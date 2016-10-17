module.exports =
    formatFrame: ({level, addr, func, file, line}) ->
        if not level? then level = 0
        fmt = "##{level}  #{addr} in #{func} ()"
        if file?
            fmt += " at #{file}:#{line}"
        return fmt

    cidentFromLine: (line, pos) ->
        cident = /^[A-Za-z0-9_\.]+/
        while (match = line.slice(pos).match cident) and pos >= 0
            ret = match[0]
            pos--
        ret

    cstr: (s)->
        esc = ''
        for c in s
            switch c
                when '"' then c = '\\"'
                when '\\' then c = '\\\\'
            esc += c
        return "\"#{esc}\""
