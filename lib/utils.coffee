module.exports =
    formatFrame: ({level, addr, func, file, line}) ->
        if not level? then level = 0
        fmt = "##{level}  #{addr} in #{func} ()"
        if file?
            fmt += " at #{file}:#{line}"
        return fmt
