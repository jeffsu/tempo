var SparseLogger = require('./sparse-logger');
var Counter      = require('./counter');

export class TimedCounter {
  include $m.EventEmitter;

  function initialize(options) {
    this.per       = options.per;
    this.nBuckets  = options.buckets; 
    this.totalTime = this.nBuckets * this.per;
    this.timeout   = options.timeout || (this.per * 2);
    this.buckets = [];
    this.cache   = {};

    this.intervalId = setInterval(#{ self.cleanup() }, this.per);
  }

  function increment(key, n) {
    return this.inc(key, n);
  }

  function inc(key, n) {
    var bucket = this.getCurrentBucket();
    this.cache[key] = (this.cache[key] || 0) + (n || 1);
    return bucket.inc(key, n);
  }

  function getCount(key, time) {
    if (time) {
      time = this.getFloor(time);
      foreach (var b in this.buckets) {
        if (time == b.time) return b.get(key);
      }
      return 0;
    } 
    
    else {
      return this.cache[key] || 0;
    }
  }

  function getExpireTime() {
    return (new Date).getTime() - this.totalTime;
  }

  function getTimes() {
    var floor = this.getFloor();
    var ret   = [];
    for (var i=0; i<this.nBuckets; i++) {
      ret.push(floor);
      floor -= this.per;
    }

    return ret;
  }

  function getKeys() {
    var ret = [];
    for (var k in this.cache) ret.push(k);
    return ret;
  }

  function getAverageHistory(numKey, denKey) {
    var times = this.getTimes();
    var ret = [];

    var numerators   = this.getHistory(numKey);
    var denominators = this.getHistory(denKey);

    foreach (var num:i in numerators) {
      var den = denominators[i];
      if (den && num) 
        ret.push(num / den);
      else 
        ret.push(null);
    }

    return ret;
  }

  function getHistory(key) {
    var times = this.getTimes();
    var history = [];
    foreach (var time in times) {
      var bucket = this.getBucket(time);
      if (!bucket) history.push(0);
      else history.push(bucket.get(key));
    }
    return history;
  }
   
  static function sync(redis, hashOfTempos, cb) {
    self.pushData(redis, hashOfTempos, #(err) {
      if (err) return cb(err);
      self.pullData(redis, hashOfTempos, cb);
    });
  }

  static function pullData(redis, hashOfTempos, cb) {
    var multi    = [];
    var handlers = [];

    for (var k in hashOfTempos) 
      handlers.push(hashOfTempos[k].multiPullData(k, multi));

    redis.multi(multi).exec(#(err, replies) {
      foreach (var h:i in handlers) h(replies);
    });
  }

  static function pushData(redis, hashOfTempos, cb) {
    var multi = [];
    for (var k in hashOfTempos) hashOfTempos[k].multiPushData(k, multi);
    redis.multi(multi).exec(#(err) { cb(err) });
  }

  function sync(redis, namespace, cb) {
    var _cb = #(err) { if (cb) return cb(err); };
    this.pushData(redis, namespace, #(err) {
      if (err) return _cb(err);
      self.pullData(redis, namespace, _cb);
    });
  }

  function multiPushData(namespace, multi) {
    var threshold = this.getFloor();
    var timeout   = this.timeout;

    foreach (var b:i in this.buckets) {
      var key = namespace + ':' + b.time;
      b.setupRedisMulti(multi, key);
      multi.push([ 'PEXPIREAT', key, b.time + this.totalTime + timeout ]);
    }

    return multi;
  }

  function multiPullData(namespace, multi) {
    var times    = this.getTimes();
    var startIdx = 0;
    var cache    = this.cache;

    foreach (var time in times) {
      multi.push([ 'hgetall', namespace + ':' + time ]);
    }

    return #(replies) {
      foreach (var time:i in times) {
        var hash = replies[i+startIdx];
        if (hash) {
          var b = self.getBucket(time, true);
          for (var k in hash) {
            var delta = b.replaceSync(k, parseInt(hash[k]));
            cache[k] = (cache[k] || 0) + delta;
            if (cache[k] <= 0) delete cache[k];
          }
        }
      }
    };
  }

  function pullData(redis, namespace, cb) {
    var multi = [];
    var handler = this.multiPullData(namespace, multi);
    if (multi.length) {
      redis.multi(multi).exec(#(err, replies) {
        if (cb && err) return cb(err);
        handler(replies);
        if (cb) cb(err);
      });
    } else {
      if (cb) cb(null);
    }
  }

  function pushData(redis, namespace, cb) {
    var multi = [];
    this.multiPushData(namespace, multi);
    if (multi.length) 
      redis.multi(multi).exec(#(err) { cb(err); });
    else cb(null);
  }

  function getCurrentBucket() {
    var floor  = this.getFloor();
    var bucket = this.buckets[this.buckets.length-1];

    if (!bucket || bucket.time != floor) {
      var b = this.newBucket(floor);
      this.buckets.push(b);
      return b;
    } else {
      return bucket;
    }
  }

  function newBucket(time) {
    var b = new Counter();
    b.time = time;
    return b;
  }

  function getBucket(time, autoVivify) {
    var beforeIdx = -1;
    foreach (var bucket:i in this.buckets) {
      if (bucket.time == time) return bucket;
      if (bucket.time > time) {
        if (autoVivify) {
          beforeIdx = i - 1;
          break;
        } else {
          return null
        }
      }
    }

    if (autoVivify) {
      var b = this.newBucket(time);
      if (beforeIdx <= 0) this.buckets.unshift(b);
      else this.buckets.splice(beforeIdx, 1, b);
      return b;
    } else {
      return null;
    }
  }

  function cleanup() {
    var first;
    var expireTime = this.getExpireTime();
    while (1) {
      var bucket = this.buckets[0];

      if (!bucket || bucket.time > expireTime) return;
      else this.shiftBucket();
    }
  }

  function shiftBucket() {
    var bucket = this.buckets.shift();
    if (!bucket) return;

    var data  = bucket.getData(),
        cache = this.cache;

    for (var k in data) {
      var cacheVal = cache[k];
      if (cacheVal === undefined) console.warn('we have a sync problem');
      else cache[k] -= data[k];
      if (cache[k] <= 0) delete cache[k];
    }
  }

  function getFloor(time) {
    time = time || (new Date).getTime();
    return time - (time % this.per);
  }
}

