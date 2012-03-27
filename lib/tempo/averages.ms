export class Averages {
  function initialize(config) {
    this.store = config.store || (new DataStore(config));
  }

  function add(key, score, count) {
    count = count || 1;
    this.store.increment(key, 'total', score);
    this.store.increment(key, 'count', count);
  }

  function getAverage(key, time) {
    if (time) {
      var score = this.store.getVal(key, 'total', time);
      var count = this.store.getVal(key, 'count', time);
      return count ? score / count : null;
    } 
    
    else {
      var score = this.store.getTotal(key, 'total');
      var count = this.store.getTotal(key, 'count');
      return count ? score / count : null;
    }
  }

  function getHistory(key) {
    return this.store.getHistory(key, [ 'total', 'count' ])
       .map(#(row) { => [ row[0], (row[2] ? row[1] / row[2] : null), row[1], row[2] ] });
  }
}
