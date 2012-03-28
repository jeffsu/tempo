export class Average {
  function initialize(config) {
    this.key   = config.key || 'default';
    this.store = config.store || (new DataStore(config));
  }

  function add(score, count) {
    count = count || 1;
    this.store.increment(this.key, 'total', score);
    this.store.increment(this.key, 'count', count);
  }

  function getAverage(time) {
    if (time) {
      var score = this.store.getVal(this.key, 'total', time);
      var count = this.store.getVal(this.key, 'count', time);
      return count ? score / count : null;
    } 
    
    else {
      var score = this.store.getTotal(this.key, 'total');
      var count = this.store.getTotal(this.key, 'count');
      return count ? score / count : null;
    }
  }

  function getHistory() {
    return this.store.getHistory(this.key, 'total', 'count')
       .map(#(row) { => [ row[0], (row[2] ? row[1] / row[2] : null), row[1], row[2] ] });
  }
}
