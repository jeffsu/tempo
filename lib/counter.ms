export class Counter {

  function initialize(options) {
    options = options || {};

    this.offset   = options.offset || 0;
    this.nbuckets = options.buckets + this.offset;
    this.per      = options.per;
    this.name     = options.name;

    this.expireOffset = options.expireOffset || 4;

    this.expireTime = (this.nbuckets + this.expireOffset) * this.per;

    this.totalTime = this.nbuckets * this.per;
    this.namespace = options.namespace;
    this.prefix    = this.namespace ? this.namespace + ':' : '';


    this.idx = 0;
    this._buckets = [];
    this._syncs   = [];

    this.floor     = this.getFloor(Date.now());
    this.nextFloor = this.floor + this.per;

    for (var i=0; i<this.nbuckets; i++) {
      this._buckets.push(Object.create(null));
      this._syncs.push(Object.create(null));
    }
  }

  function getKeys() {
    var hash = {};
    var ret  = [];

    foreach (var b:i in this._buckets) {
      var s = this._syncs[i];
      for (var k in b) hash[k] = null;
      for (var k in s) hash[k] = null;
    }

    for (var k in hash) ret.push(k);
    return ret;
  }

  function getHistory(key) {
    var ret = [];
    this.forEach(#(b, s, time, idx) {
      ret.push(self.getIdxVal(key, idx));
    });
    return ret;
  }

  function getAverageHistory(numKey, denKey) {
    var ret = [];

    this.forEach(#(b, s, time, idx) {
      var num = self.getIdxVal(numKey, idx);
      var den = self.getIdxVal(denKey, idx);

      ret.push(den == 0 ? null : num / den);
    });

    return ret;
  }


  function toTable() {
    var Table = require('cli-table');
    var table = new Table({ head: [ 'Time', 'Bucket', 'Sync' ] });

    var ret = "";
    this.forEach(#(b, s, time, idx, i) {
      table.push([ time, JSON.stringify(b), JSON.stringify(s) ]);
    });

    return table;
  }

  function toString() {
    return this.toTable().toString();
  }

  function eachCount(k, cb) {
    if (arguments.length > 2) {
      var cb = arguments[arguments.length-1];
      var keys = [];
      for (var i=0; i<(arguments.length-1); i++) keys.push(arguments[i]);

      this.forEach(#(b, s, time) {
        var vals = [];
        foreach (var k in keys) vals.push((b[k] || 0) + (s[k] || 0))
        vals.push(time);
        cb.apply(self, vals);
      });
    }

    else {
      this.forEach(#(b, s, time) {
        cb((b[k] || 0) + (s[k] || 0), time)
      });
    }
  }

  function _forEach(cb) {
    var floor = this.floor;
    for (var i=0; i<this.nbuckets; i++) {
      var idx = (i + this.idx) % this.nbuckets;
      cb(this._buckets[idx], this._syncs[idx], floor, idx, i);
      floor -= this.per;
    }
  }

  function forEach(cb) {
    var floor = this.floor;
    for (var i=this.offset; i<this.nbuckets; i++) {
      var idx = (i + this.idx) % this.nbuckets;
      cb(this._buckets[idx], this._syncs[idx], floor, idx, i);
      floor -= this.per;
    }
  }

  function tick() {
    var per = this.per;

    var nowFloor = this.getFloor();
    if (nowFloor < this.nextFloor) return;

    var deltaIdx = (nowFloor - this.floor) / per;

    var min = Math.min(this.nbuckets, deltaIdx);
    var idx = this.idx;
    for (var i=0; i<min; i++) {
      --idx;
      if (idx < 0) idx = this.nbuckets - 1;
      this.deprecate(idx);
    }

    this.idx       = idx;
    this.floor     = nowFloor;
    this.nextFloor = this.floor + per;
  }

  function getCount(key) {
    this.tick();
    var ret = 0;
    this.forEach(#(bucket, sync) { ret += (bucket[key] || 0) + (sync[key] || 0); });
    return ret;
  }

  function deprecate(idx) {
    var bucket = this._buckets[idx],
        sync   = this._syncs[idx];

    this._buckets[idx] = Object.create(null);
    this._syncs[idx]   = Object.create(null);
  }

  function increment(key, n) {
    return this.inc(key, n);
  }

  function getSyncer(redis) {
    if (this.syncer) return this.syncer;

    var Syncer  = require('./syncer');
    this.syncer = new Syncer(redis);
    this.syncer.addCounter(this);
    return this.syncer;
  }

  function sync(redis, cb) {
    this.getSyncer(redis).sync(cb);
  }

  function push(redis, cb) {
    this.getSyncer(redis).push(cb);
  }

  function pull(redis, cb) {
    this.getSyncer(redis).pull(cb);
  }

  function inc(key, n) {
    if (this.offset) throw new Error("Can't increment key if offset is used");
    this.tick();

    n = typeof n == 'number' ? n : 1;

    var curr = this._buckets[this.idx];
    curr[key] = (curr[key] || 0) + n;
  }

  function getFloor(time) {
    time = time || Date.now();
    return time - (time % this.per);
  }

  function getTimes() {
    this.tick();
    var ret = [];
    var time = this.floor;
    for (var i=0; i<this.nbuckets; i++) {
      ret.push(time);
      time -= this.per;
    }
    return ret;
  }

  function getIdxVal(key, idx) {
    this.tick();
    return (this._buckets[idx][key] || 0) + (this._syncs[idx][key] || 0)
  }

}
