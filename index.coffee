fs = require("fs")
path = require("path")
glob_rules = require("glob-rules")

class AbstractMethodError extends Error
    constructor: (name) ->
        @name = "AbstractMethodError"
        @message = "Calling abstract method `#{name}` detected."

class BaseRules
    _check: (_path) -> throw new AbstractMethodError("_check")
    _process:  (_path, _normalized) -> throw new AbstractMethodError("_process")

class FilteringRules extends BaseRules
    constructor: (options) ->
        @excludes = []
        for test in options.excludes ? []
            @excludes.push(glob_rules.tester(test))

    _check: (_path) ->
        for rule in @excludes
            return false if rule(_path)
        return true

    _process: (_path, _normalized) ->
        data = 
            path: _path
            relative: _normalized
        return data

class TransformRules extends FilteringRules
    constructor: (options) ->
        super(options)
        throw Error("Required `rules`") unless options.rules?
        @rules = []
        for test, pattern of options.rules
            @rules.push
                test: test
                pattern: pattern
                tester: glob_rules.tester(test)
                matcher: glob_rules.matcher(test)
                transformer: glob_rules.transformer(test, pattern)

    _check: (_path) ->
        for rule in @excludes
            return false if rule(_path)
        return true

    _process: (_path, _normalized) -> 
        for rule in @rules
            if rule.tester(_normalized)
                data = 
                    path: _path
                    relative: _normalized
                    result: rule.transformer(_normalized)
                    match: rule.matcher(_normalized)
                return data

## ========================================================================== ##

class BaseWalker
    constructor: (options) ->
        throw Error("Required `root`") unless options.root?
        @root = options.root

    normalize: (p) ->
        return './' + path.relative(@root, p).split(path.sep).join('/')

class BaseAsync extends BaseWalker
    constructor: (options) ->
        super(options)

        @callback = options.callback
        @complete = options.complete
        @error = options.error
        @rules = new @Rules(options)

        @_dirs = []
        @_files = []
        @_paths = []

    finished: ->
        return false if @_dirs.length > 0
        return false if @_files.length > 0
        return true

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
            _path = @_files.shift()
            _normalized = @normalize(_path)
            data = @rules._process(_path, _normalized)
            if data?
                @callback(data, => @_step())
                return
            @_step()
            return

        if @_dirs.length > 0
            dir = @_dirs.shift()
            fs.readdir dir, (err, files) =>
                return @error(err) if err?
                files.forEach (file) =>
                    _path = path.join(dir, file)
                    _normalized = @normalize(_path)
                    return unless @rules._check(_normalized)
                    @_paths.push(_path)
                @_step()
            return

        @complete()

    walk: ->
        @_dirs.push(@root)
        @_step()
        return 

class BaseSync extends BaseWalker
    constructor: (options) ->
        super(options)
        @rules = new @Rules(options)
        @_dirs = []
        @_files = []

    _step: (_path) ->
        _normalize = @normalize(_path)
        return unless @rules._check(_normalize)
        stat = fs.statSync(_path)
        return unless stat?
        if stat.isDirectory()
            @_dirs.push(_path)
        return unless stat.isFile()
        data = @rules._process(_path, _normalize)
        @_files.push(data) if data?

    walk: ->
        @_dirs.push(@root)
        while @_dirs.length > 0
            dir = @_dirs.shift()
            for file in fs.readdirSync(dir)
                _path = path.join(dir, file)
                @_step(_path)
        return @_files

class AsyncWalker extends BaseAsync
    Rules: FilteringRules

class SyncWalker extends BaseSync
    Rules: FilteringRules

class AsyncTransformer extends BaseAsync
    Rules: TransformRules

class SyncTransformer extends BaseSync
    Rules: TransformRules

exports.AsyncWalker = AsyncWalker
exports.SyncWalker = SyncWalker
exports.AsyncTransformer = AsyncTransformer
exports.SyncTransformer = SyncTransformer

exports.walk = (options) ->
    walker = new AsyncWalker(options)
    return walker.walk()

exports.walkSync = (options) ->
    walker = new SyncWalker(options)
    return walker.walk()

exports.transform = (options) ->
    transformer = new AsyncTransformer(options)
    return transformer.walk()

exports.transformSync = (options) ->
    transformer = new SyncTransformer(options)
    return transformer.walk()