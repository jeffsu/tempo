var SparseLogger = require('./sparse-logger');
var Counter      = require('./counter');

export class DataStore {
  include $m.EventEmitter;

  function initialize(options) {
    this.per       = options.per;
    this.nBuckets  = options.buckets; 
    this.totalTime = this.nBuckets * this.per;
    this.timeout   = options.timeout || (this.per * 2);
    this.buckets = [];
    this.cache   = {};
  }

  function increment(key, n) {
    return this.inc(key, n);
  }

  function inc(key, n) {
    this.cleanup();
    var bucket = this.getCurrentBucket();
    this.cache[key] = (this.cache[key] || 0) + (n || 1);
    return bucket.inc(key, n);
  }

  function getCount(key, time) {
    this.cleanup();
    if (time) {
      time = this.getFloor(time);
      foreach (var b in this.buckets) {
        if (time == b.time) return b.get(key);
      }
    } else {
      var n = 0;
      for (var i in this.buckets) n += this.buckets[i].get(key);
    }
    return n;
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

  function getHistory(key) {
    var times = this.getTimes();
    var history = [];
    foreach (var time in times) {
      var bucket = this.getBucket(time);
      if (!bucket) history.push(0);
      else history.push(bucket.get(key));
    }
  }

  function sync(redis, namespace, cb) {
    var _cb = #(err) { if (cb) return cb(err); };

    this.pushData(redis, namespace, #{ 
      if (err) return _cb(err);
      self.pullData(redis, namespace, _cb);
    });
  }

  function sync(redis, namespace) {
    self.emit('sync-start');
    var threshold = this.getFloor();
    var multi = [];
    var timeout = this.timeout;
    for (var i in this.buckets) {
      var bucket = this.buckets[i];
      bucket.sync(namespace, multi);
      multi.push([ 'PEXPIREAT', bucket.getMainKey(namespace), bucket.time + timeout ]);
    }

    redis.multi(multi).exec(#(err, replies) {
      if (err) return self.emit('sync-push-error', err);
      self.emit('sync-push');
      self.syncPull(redis, namespace);
    });
  }

  function syncPull(redis, namespace) {
    var times = self.getTimes();
    var multi = times.map(#{ => [ 'HGETALL', namespace + ':' + $1 ] });
    redis.multi(multi).exec(#(err, replies) {
      foreach (var r:i in replies) {
        if (r) {
          var bucket = self.getBucket(times[i], true);
          for (var k in r) bucket.syncSet(k, parseInt(r[k]));
        }
      }
    });
  }

  function getKeys() {
    this.cleanup();

    var already = {};
    var ret     = [];
    for (var i in this.buckets) {
      this.buckets[i].populateKeys(ret, already);
    }
    return ret;
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
    foreach (var bucket:i in this.buckets) {
      if (bucket.time == time) return bucket;
      if (autoVivify && bucket.time > time) {
        var b = this.newBucket(time);
        this.buckets.splice(i, 1, b);
        return b;
      }
    }

    if (autoVivify) {
      var b = this.newBucket(time);
      this.buckets.push(b);
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
      if (!bucket) return;
      if (bucket.time < expireTime) this.shiftBucket();
      else return;
    }
  }

  function shiftBucket() {
    var bucket = this.buckets.shift();
    if (!bucket) return;

    var data  = bucket.getData(),
        cache = this.cache;

    for (var k in data) {
      var cacheVal = cache[k];
      if (cacheVal === undefined) console.warn('we hae a sync problem');
      else cache[k] -= data[k];
      if (cache[k] <= 0) delete cache[k];
    }
  }

  function getFloor(time) {
    time = time || (new Date).getTime();
    return time - (time % this.per);
  }
}

