var Matcher, fs, glob_rules, path;

fs = require("fs");

path = require("path");

glob_rules = require("glob-rules");

Matcher = (function() {
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
        test: test,
        pattern: pattern,
        tester: glob_rules.tester(test),
        transformer: glob_rules.transformer(test, pattern)
      });
    }
    this.excludes = [];
    _ref2 = (_ref1 = options.exclude) != null ? _ref1 : [];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      test = _ref2[_i];
      this.excludes.push(glob_rules.tester(test));
    }
    this.callback = options.callback;
    this.complete = options.complete;
    this.error = options.error;
    this._dirs = [];
    this._files = [];
    this._paths = [];
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

  Matcher.prototype.normalize = function(p) {
    return './' + path.relative(".", p).split(path.sep).join('/');
  };

  Matcher.prototype.step = function() {
    var data, dir, f, file, rule, _i, _len, _ref;
    if (this._paths.length > 0) {
      f = this._paths.shift();
      fs.stat(f, (function(_this) {
        return function(err, stat) {
          if (err != null) {
            return _this.error(err);
          }
          if (stat == null) {
            return;
          }
          if (stat.isDirectory()) {
            _this._dirs.push(f);
          }
          if (stat.isFile()) {
            _this._files.push(f);
          }
          return _this.step();
        };
      })(this));
      return;
    }
    while (this._files.length > 0) {
      file = this._files.shift();
      _ref = this.rules;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rule = _ref[_i];
        if (rule.tester(file)) {
          data = {
            source: file,
            result: rule.transformer(file)
          };
          this.callback(data, (function(_this) {
            return function() {
              return _this.step();
            };
          })(this));
          return;
        }
      }
      this.step();
      return;
    }
    if (this._dirs.length > 0) {
      dir = this._dirs.shift();
      fs.readdir(dir, (function(_this) {
        return function(err, files) {
          if (err != null) {
            return _this.error(err);
          }
          files.forEach(function(file) {
            var _j, _len1, _ref1;
            f = _this.normalize(path.join(dir, file));
            _ref1 = _this.excludes;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              rule = _ref1[_j];
              if (rule(f)) {
                return;
              }
            }
            return _this._paths.push(f);
          });
          return _this.step();
        };
      })(this));
      return;
    }
    return this.complete();
  };

  Matcher.prototype.walk = function(dir) {
    this._dirs.push(dir);
    return this.step();
  };

  return Matcher;

})();

exports.Matcher = Matcher;

exports.walk = function(dir, options) {
  var matcher;
  matcher = new Matcher(options);
  matcher.walk(dir);
};
