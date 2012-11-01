export class SparseLogger {
  private {
    var DEFAULT_LIMIT = 100;
  }

  function initialize(limit) {
    this.limit  = limit || DEFAULT_LIMIT;
    this.empty();
  }

  function getLogs() {
    return this.logs;
  }

  function empty() {
    this.count = 0;
    this.logs = [];
  }

  function shouldLog() {
    var idx  = this.count % this.limit;
    var trim = this.count - idx;
    if (trim > 0) {
      var ratio = 1 / (trim / this.limit);
      return (ratio >= Math.random());
    } 

    return true;
  }

  function log(msg, force) {
    var idx = this.count % this.limit;

    if (force || this.shouldLog()) this.logs[idx] = msg;
    this.count++;
  }
}
