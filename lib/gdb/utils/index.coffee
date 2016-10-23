module.exports =
    cstr: (s)->
        esc = ''
        for c in s
            switch c
                when '"' then c = '\\"'
                when '\\' then c = '\\\\'
            esc += c
        return "\"#{esc}\""

    bufferedProcess: require './buffered-process'
