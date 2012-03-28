export class DataStore {
  include $m.EventEmitter;

  function initialize(config) {
    this.per      = config.per;
    this.nBuckets = config.buckets;
    this.totalTime = this.per * this.nBuckets;

    this.sync    = {};
    this.history = {};
  }

  function increment(key, attr, n) {
    var data = this.getBucket(this.now(), this.history).data;
    var item = data[key] || (data[key] = {});
    var ret = item[attr] = (item[attr] || 0) + (n === undefined ? 1 : n);
    return ret;
  }

  function getVal(key, attr, time) {
    time = this.getFloor(time || this.now());

    var hVal = this.getValFromHash(this.history, time, key, attr);
    var sVal = this.getValFromHash(this.sync, time, key, attr);

    if (sVal === undefined && hVal === undefined) {
      return null;
    } else {
      return (sVal || 0) + (hVal || 0);
    }
  }

  function flushHistory() {
    for (var time in this.history) {
      var hData = this.history[time].data;
      var sData = this.getBucket(time, this.sync).data;

      for (var key in hData) {
        var hItem = hData[key];
        var sItem = sData[key] || (sData[key] = {});

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
      var data = this.history[time].data;
      for (var key in data) {
        var item = data[key];
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

        var data = self.getBucket(time, self.sync).data;
        var item = data[key] || (data[key] = {});
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

    var item = bucket.data[key];
    if (item && (attr in item)) return item[attr];
    return null;
  }

  function getHistory(key, attr) {
    var floor = this.getFloor();
    var attrs = attr instanceof Array ? attr : [ attr ];
    var ret = [];

    for (var i=this.nBuckets-1; i>=0; i--) {
      var time = floor - (i * this.per);
      var row  = [ time ];
      foreach (var attr in attrs) {
        row.push(this.getVal(key, attr, time));
      }
      ret.push(row);
    }

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
    return { data: {}, time: floor, expireAt: floor + this.totalTime };
  }

  function getFloor(time) {
    time = time || this.now();
    return time - (time % this.per);
  }

  function now() {
    return (new Date()).getTime();
  }

}
