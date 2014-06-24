fs = require("fs")
path = require("path")
glob_rules = require("glob-rules")

class Matcher
    constructor: (options) ->
        throw Error("Required `rules`") unless options.rules?
        @rules = []
        for test, pattern of options.rules
            @rules.push
                test: test
                pattern: pattern
                tester: glob_rules.tester(test)
                transformer: glob_rules.transformer(test, pattern)
        @excludes = []
        for test in options.exclude ? []
            @excludes.push(glob_rules.tester(test))
        @callback = options.callback
        @complete = options.complete
        @error = options.error
        @_dirs = []
        @_files = []
        @_paths = []

    finished: ->
        return false if @_dirs.length > 0
        return false if @_files.length > 0
        return true

    normalize: (p) ->
        return './' + path.relative(".", p).split(path.sep).join('/')

    step: ->
        if @_paths.length > 0
            f = @_paths.shift()
            fs.stat f, (err, stat) =>
                return @error(err) if err?
                return unless stat?
                if stat.isDirectory()
                    @_dirs.push(f)
                if stat.isFile()
                    @_files.push(f)
                @step()
            return

        while @_files.length > 0
            file = @_files.shift()
            for rule in @rules
                if rule.tester(file)
                    data =
                        source: file
                        result: rule.transformer(file)
                    @callback(data, => @step())
                    return
            @step()
            return

        if @_dirs.length > 0
            dir = @_dirs.shift()
            fs.readdir dir, (err, files) =>
                return @error(err) if err?
                files.forEach (file) =>
                    f = @normalize(path.join(dir, file))
                    for rule in @excludes
                        return if rule(f)
                    @_paths.push(f)
                @step()
            return

        @complete()

    walk: (dir) ->
        @_dirs.push(dir)
        @step()

exports.Matcher = Matcher

exports.walk = (dir, options) ->
    matcher = new Matcher(options)
    matcher.walk(dir)
    return 
