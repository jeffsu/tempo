var DataStore = require('./data-store');

export class Counter {
  function initialize(config) {
    this.key   = config.key;
    this.store = config.store || (new DataStore(config));
  }

  function increment(attr, n) {
    n = n === undefined ? 1 : n;
    this.store.addVal(this.key, attr, n);
  }

  function getCount(attr, time) {
    if (time) {
      this.store.getVal(this.key, attr, time);
    } else {
      this.store.getTotal(this.key, attr);
    }
  }
}
