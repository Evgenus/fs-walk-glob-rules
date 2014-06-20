var glob_rules;

glob_rules = require("glob-rules");

module["export"].Matcher = (function() {
  var check;

  function Matcher(options) {
    var pattern, test, _i, _len, _ref, _ref1, _ref2;
    if (options.rules == null) {
      throw Error("Required `rules`");
    }
    this.rules = [];
    _ref = options.rules;
    for (test in _ref) {
      pattern = _ref[test];
      this.rules.push({
        test: glob_rules.tester(test),
        transformer: glob_rules.transformer(test, pattern)
      });
    }
    this.excludes = [];
    _ref2 = (_ref1 = option.exclude) != null ? _ref1 : [];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      test = _ref2[_i];
      this.excludes.push(glob_rules.tester(test));
    }
    this.callback = option.callback;
    this._dirs = [];
    this._files = [];
  }

  Matcher.prototype.finished = function() {
    if (this._dirs.length > 0) {
      return false;
    }
    if (this._files.length > 0) {
      return false;
    }
    return true;
  };

  check = function(dir, stat) {
    var relative, rule, _i, _len, _ref;
    relative = '/' + path.relative(".", dir).split(path.sep).join('/');
    _ref = this.excludes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      rule = _ref[_i];
      if (rule.test(relative)) {
        return false;
      }
    }
    return true;
  };

  Matcher.prototype.step = function() {
    var dir, f, file;
    if (this._files.length > 0) {
      file = this._dirs.shift();
      f = path.join(dir, file);
    }
    if (this._dirs.length > 0) {
      dir = this._dirs.shift();
      fs.readdir(dir, function(err, files) {
        if (err != null) {
          return this.callback(err, null);
        }
        return files.forEach(function(file) {
          var stat;
          f = path.join(dir, file);
          stat = fs.stat(f);
          if (!stat) {
            return;
          }
          if (stat.isDirectory() && this.check(f, stat)) {
            this._dirs.push(f);
          }
          if (stat.isFile()) {
            return this._files.push(f);
          }
        });
      });
      return step();
    }
  };

  Matcher.prototype.walk = function(dir) {
    this._dirs.push(dir);
    return step();
  };

  return Matcher;

})();
