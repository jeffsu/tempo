var DataStore = require('./data-store');
var Counter   = require('./counter');

export class AttrCounter {
  function initialize(config) {
    this.key   = config.key;
    this.store = config.store || (new DataStore(config));
    this.attr = config.attr;
  }

  function increment(n) {
    n = n === undefined ? 1 : n;
    this.store.addVal(this.key, this.attr, n);
  }

  function getCount(time) {
    if (time) {
      this.store.getVal(this.key, this.attr, time);
    } else {
      this.store.getTotal(this.key, this.attr);
    }
  }
}
