var DataStore = require('data-store');

export class Average {
  function initialize(config) {
    this.store = new DataStore(config);
  }

  function add(score, count) {
    count = count || 1;
    this.store.addVal('average', 'score', score);
    this.store.addVal('average', 'count', count);
  }

  function getAverage(time) {
    var score = this.store.getTotal('average', 'score');
    var count = this.store.getTotal('average', 'count');
    return score / count;
  }
  
}
