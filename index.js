var Matcher;

Matcher = (function() {
  var check;

  function Matcher(options) {
    var pattern, test, _ref, _ref1;
    if (options.rules == null) {
      throw Error("Required `rules`");
    }
    this.rules = [];
    _ref = options.rules;
    for (test in _ref) {
      pattern = _ref[test];
      this.rules.push({
        test: globStringToRegex(test),
        pattern: pattern
      });
    }
    this.excludes = (_ref1 = option.exclude) != null ? _ref1 : [];
    this.callback = option.callback;
    this.dirs = [];
    this.files = [];
  }

  Matcher.prototype.finished = function() {
    if (this.dirs.length > 0) {
      return false;
    }
    if (this.files.length > 0) {
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
    if (this.files.length > 0) {
      file = this.dirs.shift();
      f = path.join(dir, file);
    }
    if (this.dirs.length > 0) {
      dir = this.dirs.shift();
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
            this.dirs.push(f);
          }
          if (stat.isFile()) {
            return files.push(f);
          }
        });
      });
      return step();
    }
  };

  Matcher.prototype.walk = function(dir) {
    this.dirs.push(dir);
    return step();
  };

  return Matcher;

})();
