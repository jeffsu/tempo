var nested = require('nested');
export class DataStore {
  include $m.EventEmitter;

  function initialize(config) {
    this.per      = config.per;
    this.nBuckets = config.buckets;
    this.logCount = config.logs || (this.per / 1000);

    this.totalTime = this.per * this.nBuckets;

    this.sync    = {};
    this.history = {};
  }

  function increment(key, attr, n) {
    var item = this.getBucket(this.now(), this.history).items(key);
    var ret = item[attr] = (item[attr] || 0) + (n === undefined ? 1 : n);
    return ret;
  }

  function getVal(key, attr, time) {
    time = this.getFloor(time || this.now());

    var hVal = this.getValFromHash(this.history, time, key, attr);
    var sVal = this.getValFromHash(this.sync, time, key, attr);

    if (sVal === null && hVal === null) {
      return null;
    } else {
      return (sVal || 0) + (hVal || 0);
    }
  }

  function flushHistory() {
    for (var time in this.history) {
      var hItems = this.history[time].items;
      var sItems = this.getBucket(time, this.sync).items;

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

  function redisSync(redis, prefix) {
    var commands  = [];
    var expires   = [];
    var redisKeys = [];

    prefix = prefix ? prefix + ':' : '';

    for (var time in this.history) {
      var items = this.history[time].items;
      for (var key in items.data) {
        var item = items(key);
        for (var attr in item) {
          var val = item[attr];
          var redisKey = prefix + key + ':' + time;
          redisKeys.push([ time, key, attr ]);
          commands.push([ 'HINCRBY', redisKey, attr, val ]);
          expires.push([ 'EXPIREAT', redisKey, time + this.totalTime ]);
        }
      }
    }

    foreach (var exp in expires) {
      commands.push(exp);
    }

    var multi = redis.multi(commands);
    multi.exec(#(err, results) {
      if (err) return;
      foreach (var rkey:i in redisKeys) {
        var time = rkey[0];
        var key  = rkey[1];
        var attr = rkey[2];

        var item = self.getBucket(time, self.sync).items(key);
        item[attr] = results[i];
      }
      self.emit('sync');
    });

    this.flushHistory();
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
