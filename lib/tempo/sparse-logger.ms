
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

  function log(msg) {
    var idx = this.count % this.limit;

    var trim = this.count - idx;
    if (trim > 0) {
      var ratio = 1 / (trim / this.limit);
      if (ratio >= Math.random()) this.logs[idx] = msg;
    } else {
      this.logs[idx] = msg;
    }

    this.count++;
  }

}
