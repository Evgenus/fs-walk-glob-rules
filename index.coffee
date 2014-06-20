glob_rules = require("glob-rules")

class module.export.Matcher
    constructor: (options) ->
        throw Error("Required `rules`") unless options.rules?
        @rules = []
        for test, pattern of options.rules
            @rules.push
                test: glob_rules.tester(test)
                transformer: glob_rules.transformer(test, pattern)
        @excludes = []
        for test in option.exclude ? []
            @excludes.push(glob_rules.tester(test))
        @callback = option.callback
        @_dirs = []
        @_files = []

    finished: ->
        return false if @_dirs.length > 0
        return false if @_files.length > 0
        return true

    check = (dir, stat) ->
        relative = '/' + path.relative(".", dir).split(path.sep).join('/')
        for rule in @excludes
            return false if rule.test(relative)
        return true

    step: ->
        if @_files.length > 0
            file = @_dirs.shift()
            f = path.join(dir, file)

        if @_dirs.length > 0
            dir = @_dirs.shift()
            fs.readdir dir, (err, files) ->
                return @callback(err, null) if err?
                files.forEach (file) ->
                    f = path.join(dir, file)
                    stat = fs.stat(f)
                    return unless stat
                    if stat.isDirectory() and @check(f, stat)
                        @_dirs.push(f)
                    if stat.isFile()
                        @_files.push(f)
            step()

    walk: (dir) ->
        @_dirs.push(dir)
        step()
