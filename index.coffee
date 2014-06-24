fs = require("fs")
path = require("path")
glob_rules = require("glob-rules")

class Walker
    constructor: (options) ->
        throw Error("Required `rules`") unless options.rules?
        @root = options.root
        @rules = []
        for test, pattern of options.rules
            @rules.push
                test: test
                pattern: pattern
                tester: glob_rules.tester(test)
                transformer: glob_rules.transformer(test, pattern)
        @excludes = []
        for test in options.excludes ? []
            @excludes.push(glob_rules.tester(test))

    finished: ->
        return false if @_dirs.length > 0
        return false if @_files.length > 0
        return true

    normalize: (p) ->
        return './' + path.relative(".", p).split(path.sep).join('/')

class AsyncWalker extends Walker
    constructor: (options) ->
        super(options)

        @callback = options.callback
        @complete = options.complete
        @error = options.error

        @_dirs = []
        @_files = []
        @_paths = []

    _step: ->
        if @_paths.length > 0
            _path = @_paths.shift()
            fs.stat _path, (err, stat) =>
                return @error(err) if err?
                return unless stat?
                if stat.isDirectory()
                    @_dirs.push(_path)
                if stat.isFile()
                    @_files.push(_path)
                @_step()
            return

        while @_files.length > 0
            file = @_files.shift()
            for rule in @rules
                if rule.tester(file)
                    data =
                        source: file
                        result: rule.transformer(file)
                    @callback(data, => @_step())
                    return
            @_step()
            return

        if @_dirs.length > 0
            dir = @_dirs.shift()
            fs.readdir dir, (err, files) =>
                return @error(err) if err?
                files.forEach (file) =>
                    _path = @normalize(path.join(dir, file))
                    for rule in @excludes
                        return if rule(_path)
                    @_paths.push(_path)
                @_step()
            return

        @complete()

    walk: ->
        @_dirs.push(@root)
        @_step()
        return 

class SyncWalker extends Walker
    constructor: (options) ->
        super(options)
        @_dirs = []
        @_files = []

    _step: (_path) ->
        for rule in @excludes
            return if rule(_path)
        stat = fs.statSync(_path)
        return unless stat?
        if stat.isDirectory()
            @_dirs.push(_path)
        return unless stat.isFile()
        for rule in @rules
            if rule.tester(_path)
                data =
                    source: _path
                    result: rule.transformer(_path)
                @_files.push(data)
                break

    walk: ->
        @_dirs.push(@root)
        while @_dirs.length > 0
            dir = @_dirs.shift()
            for file in fs.readdirSync(dir)
                @_step(@normalize(path.join(dir, file)))
        return @_files

exports.Walker = Walker
exports.AsyncWalker = AsyncWalker
exports.SyncWalker = SyncWalker

exports.walk = (options) ->
    walker = new AsyncWalker(options)
    return walker.walk()

exports.walkSync = (options) ->
    walker = new SyncWalker(options)
    return walker.walk()
