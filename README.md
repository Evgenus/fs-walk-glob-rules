#fs-walk-glob-rules [![Build Status](https://drone.io/github.com/Evgenus/fs-walk-glob-rules/status.png)](https://drone.io/github.com/Evgenus/fs-walk-glob-rules/latest)

[![Dependency Status](https://david-dm.org/Evgenus/fs-walk-glob-rules.svg)](https://david-dm.org/Evgenus/fs-walk-glob-rules)
[![devDependency Status](https://david-dm.org/Evgenus/fs-walk-glob-rules/dev-status.svg)](https://david-dm.org/Evgenus/fs-walk-glob-rules#info=devDependencies)
[![GitHub version](https://badge.fury.io/gh/Evgenus%2Ffs-walk-glob-rules.svg)](http://badge.fury.io/gh/Evgenus%2Ffs-walk-glob-rules)

Walk files using glob rules and transform paths with patterns

This project is like [glob], but it uses [glob-rules] instead of [minimatch].

## API

### Async

`walker.transform` - asynchronous function with 3 callbacks. Single parameter is a hash of options. This function return nothing.
* `root` - start path of walking and relativity point for paths matching.
* `rules` - dictionary of paths transformations
* `excludes` - list of patterns for path to be exclude. If some forder matches that path, means that all nested files and folders will be excluded, even if they will not match this pattern.
* `callback` - being called on each matched filepath. First parameter is data object with source relative path and path transformed with pattern. Second parameter - function that should be called when current path is already processed and we can proceed to next one. 
* `error` - being called in error situations (walking from inexistible folder). The only parameter is an error object.
* `completted` - being called then no more path to be returned and walking is finished. Has no parameters. 

### Example

```javascript
walker.transform({
  root: "/",
  rules: {
    "./(a*/*.js)": "$1"
  },
  excludes: [
    "./aa/**"
  ],
  callback: function(data, next) {
    console.log(data.source, data.result);
    next();
  },
  error: function(error) {
    console.error(error);
  },
  complete: function() {
      // expect no more data
  }
});
```

### Sync

`walker.transformSync` - synchronous function that returns list of data-objects, like ones transferred into `callback` above. Single parameter is a hash of options. Parameters `root`, `rules` and `excludes` have some meaning as above.

### Example

```javascript
var walked = walker.transformSync({
  root: "/",
  rules: {
    "./(a*/*.js)": "$1"
  },
  excludes: ["./aa/**"]
});
```

### Compiling project

```
cake build
```

### Testing 

```
npm test
```

## Copyright and license

Code and documentation copyright 2014 Eugene Chernyshov. Code released under [the MIT license](LICENSE).

[![Total views](https://sourcegraph.com/api/repos/github.com/Evgenus/fs-walk-glob-rules/counters/views.png)](https://sourcegraph.com/github.com/Evgenus/fs-walk-glob-rules)
[![Views in the last 24 hours](https://sourcegraph.com/api/repos/github.com/Evgenus/fs-walk-glob-rules/counters/views-24h.png)](https://sourcegraph.com/github.com/Evgenus/fs-walk-glob-rules)
[![library users](https://sourcegraph.com/api/repos/github.com/Evgenus/fs-walk-glob-rules/badges/library-users.png)](https://sourcegraph.com/github.com/Evgenus/fs-walk-glob-rules)
[![xrefs](https://sourcegraph.com/api/repos/github.com/Evgenus/fs-walk-glob-rules/badges/xrefs.png)](https://sourcegraph.com/github.com/Evgenus/fs-walk-glob-rules)

[glob]: https://www.npmjs.org/package/glob
[glob-rules]: https://www.npmjs.org/package/glob-rules
[minimatch]: https://www.npmjs.org/package/minimatch