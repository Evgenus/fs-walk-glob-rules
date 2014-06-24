var AsyncWalker, SyncWalker, Walker, fs, glob_rules, path,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

fs = require("fs");

path = require("path");

glob_rules = require("glob-rules");

Walker = (function() {
  function Walker(options) {
    var pattern, test, _i, _len, _ref, _ref1, _ref2;
    if (options.rules == null) {
      throw Error("Required `rules`");
    }
    this.root = options.root;
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
    _ref2 = (_ref1 = options.excludes) != null ? _ref1 : [];
    for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
      test = _ref2[_i];
      this.excludes.push(glob_rules.tester(test));
    }
  }

  Walker.prototype.finished = function() {
    if (this._dirs.length > 0) {
      return false;
    }
    if (this._files.length > 0) {
      return false;
    }
    return true;
  };

  Walker.prototype.normalize = function(p) {
    return './' + path.relative(".", p).split(path.sep).join('/');
  };

  return Walker;

})();

AsyncWalker = (function(_super) {
  __extends(AsyncWalker, _super);

  function AsyncWalker(options) {
    AsyncWalker.__super__.constructor.call(this, options);
    this.callback = options.callback;
    this.complete = options.complete;
    this.error = options.error;
    this._dirs = [];
    this._files = [];
    this._paths = [];
  }

  AsyncWalker.prototype._step = function() {
    var data, dir, file, rule, _i, _len, _path, _ref;
    if (this._paths.length > 0) {
      _path = this._paths.shift();
      fs.stat(_path, (function(_this) {
        return function(err, stat) {
          if (err != null) {
            return _this.error(err);
          }
          if (stat == null) {
            return;
          }
          if (stat.isDirectory()) {
            _this._dirs.push(_path);
          }
          if (stat.isFile()) {
            _this._files.push(_path);
          }
          return _this._step();
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
              return _this._step();
            };
          })(this));
          return;
        }
      }
      this._step();
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
            _path = _this.normalize(path.join(dir, file));
            _ref1 = _this.excludes;
            for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
              rule = _ref1[_j];
              if (rule(_path)) {
                return;
              }
            }
            return _this._paths.push(_path);
          });
          return _this._step();
        };
      })(this));
      return;
    }
    return this.complete();
  };

  AsyncWalker.prototype.walk = function() {
    this._dirs.push(this.root);
    this._step();
  };

  return AsyncWalker;

})(Walker);

SyncWalker = (function(_super) {
  __extends(SyncWalker, _super);

  function SyncWalker(options) {
    SyncWalker.__super__.constructor.call(this, options);
    this._dirs = [];
    this._files = [];
  }

  SyncWalker.prototype._step = function(_path) {
    var data, rule, stat, _i, _j, _len, _len1, _ref, _ref1, _results;
    _ref = this.excludes;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      rule = _ref[_i];
      if (rule(_path)) {
        return;
      }
    }
    stat = fs.statSync(_path);
    if (stat == null) {
      return;
    }
    if (stat.isDirectory()) {
      this._dirs.push(_path);
    }
    if (!stat.isFile()) {
      return;
    }
    _ref1 = this.rules;
    _results = [];
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      rule = _ref1[_j];
      if (rule.tester(_path)) {
        data = {
          source: _path,
          result: rule.transformer(_path)
        };
        this._files.push(data);
        break;
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  SyncWalker.prototype.walk = function() {
    var dir, file, _i, _len, _ref;
    this._dirs.push(this.root);
    while (this._dirs.length > 0) {
      dir = this._dirs.shift();
      _ref = fs.readdirSync(dir);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        this._step(this.normalize(path.join(dir, file)));
      }
    }
    return this._files;
  };

  return SyncWalker;

})(Walker);

exports.Walker = Walker;

exports.AsyncWalker = AsyncWalker;

exports.SyncWalker = SyncWalker;

exports.walk = function(options) {
  var walker;
  walker = new AsyncWalker(options);
  return walker.walk();
};

exports.walkSync = function(options) {
  var walker;
  walker = new SyncWalker(options);
  return walker.walk();
};
