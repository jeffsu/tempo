var nested = require('nested');
var RedisSyncer = require('./redis-syncer');

export class DataStore {
  include $m.EventEmitter;

  function initialize(config) {
    this.per      = config.per;
    this.nBuckets = config.buckets;
    this.logCount = config.logs || (this.per / 1000);

    this.totalTime = this.per * this.nBuckets;

    this.syncHistory = {};
    this.history     = {};
  }

  function stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }
  }

  function increment(key, attr, n) {
    var item = this.getBucket(this.now(), this.history).items(key);
    var ret = item[attr] = (item[attr] || 0) + (n === undefined ? 1 : n);
    return ret;
  }

  function getVal(key, attr, time) {
    time = this.getFloor(time || this.now());

    var hVal = this.getValFromHash(this.history, time, key, attr);
    var sVal = this.getValFromHash(this.syncHistory, time, key, attr);

    if (sVal === null && hVal === null) {
      return null;
    } else {
      return (sVal || 0) + (hVal || 0);
    }
  }

  function flushHistory() {
    for (var time in this.history) {
      var hItems = this.history[time].items;
      var sItems = this.getBucket(time, this.syncHistory).items;

      for (var key in hItems.data) {
        var hItem = hItems(key);
        var sItem = sItems(key);

        for (var attr in hItem) {
          sItem[attr] = (sItem[attr] || 0) + hItem[attr];
          hItem[attr] = 0;
        }
      }
    }
  }

  function sync(prefix, redis, interval) {
    var syncer = new RedisSyncer(prefix, redis, this);
    syncer.sync();
    return setInterval(#{ syncer.sync() }, interval);
  }

  function getTotal(key, attr) {
    var total = 0;
    var floor = this.getFloor();

    for (var i=0; i<this.nBuckets; i++) {
      var time = floor - (i * this.per);
      var val  = this.getVal(key, attr, time);
      if (val !== undefined) total += val;
    }

    return total;
  }

  function getValFromHash(hash, time, key, attr) {
    var bucket = this.getBucket(time, hash, true);
    if (!bucket) return null;

    var items = bucket.items;
    if (items.containsKey(key)) {
      var item = bucket.items(key);
      return item[attr];
    } 
    return null;
  }

  // <key>, <attr1>, <attr2>, ...
  function getHistory() {
    var key   = arguments[0];
    var floor = this.getFloor();
    var ret = [];

    for (var i=this.nBuckets-1; i>=0; i--) {
      var time = floor - (i * this.per);
      var row  = [ time ];

      for (var j=1; j<arguments.length; j++) {
        var attr = arguments[j];
        row.push(this.getVal(key, attr, time));
      }
      ret.push(row);
    }

    return ret;
  }

  /*
   * TODO
   */
  function log(log) {
    var bucket = this.getBucket(time || this.now(), this.history);
    if (bucket.logCount > this.logLimit) {
     
    } else {
       bucket.logs.push(log);
    }

    bucket.logCount++;
    return ret;

  }

  function getBucket(time, container, noCreate) {
    var floor  = this.getFloor(time);
    var bucket = container[floor];
    if (noCreate || bucket) return bucket;

    // out of bounds
    var now = this.now();
    if (floor > now || floor < (now - this.totalTime)) return null;

    bucket = container[floor] = this.createBucket(floor);
    setTimeout(#{ delete container[floor] }, this.expireAt - now);
    return bucket;
  }

  function createBucket(floor) {
    return { items: nested({ of: {} }), time: floor, expireAt: floor + this.totalTime, logs: [], logCount: 0 };
  }

  function getFloor(time) {
    time = time || this.now();
    return time - (time % this.per);
  }

  function now() {
    return (new Date()).getTime();
  }

}
