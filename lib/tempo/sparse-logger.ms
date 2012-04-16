
export class SparseLogger {
  private {
    var INFO  = 0;
    var DEBUG = 1;
    var WARN  = 2;
    var ERROR = 3;
    var FATAL = 4;

    var nested = require('nested');
  }

  function initialize(limit) {
    this.limit = limit;
    this.count = 0;
    this.logs  = nested({ of: [] });
  }

  function warn(msg) {
    return arguments.length > 0 ? this.log(WARN, msg) : this.logs(WARN);
  }

  function debug(msg) {
    return arguments.length > 0 ? this.log(DEBUG, msg) : this.logs(DEBUG);
  }

  function info(msg) {
    return arguments.length > 0 ? this.log(INFO, msg) : this.logs(INFO);
  }

  function error(msg) {
    return arguments.length > 0 ? this.log(ERROR, msg) : this.logs(ERROR);
  }

  function fatal(msg) {
    return arguments.length > 0 ? this.log(FATAL, msg) : this.logs(FATAL);
  }

  function log(level, msg) {

    var log = this.logs(level);
    var idx = this.count % this.limit;

    var trim = this.count - idx;
    if (trim > 0) {
      var ratio = 1 / (trim / this.limit);
      if (ratio >= Math.random()) log[idx] = msg;
    } else {
      log[idx] = msg;
    }

    this.count++;
  }

}
