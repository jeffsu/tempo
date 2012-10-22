var Syncer = require('./syncer');
export class Counter {
  private {
    var NOW = #{ => (new Date).getTime() };
  }

  function initialize(options) {
    this.nbuckets = options.buckets;
    this.per      = options.per;

    this.expireTime = (this.nbuckets + 2) * this.per;

    this.totalTime = this.nbuckets * this.per;
    this.namespace = options.namespace;
    this.prefix    = this.namespace ? this.namespace + ':' : '';


    this.idx = 0;
    this._buckets = [];
    this._syncs   = [];

    this.floor     = this.getFloor(NOW());
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
    var table = new Table({ head: [ '', 'Bucket', 'Sync' ] });

    var ret = "";
    this.forEach(#(b, s, time, idx, i) {
      table.push([ idx, JSON.stringify(b), JSON.stringify(s) ]);
    });

    return table;
  }

  function toString() {
    return this.toTable().toString();
  }

  function forEach(cb) {
    var floor = this.floor;
    for (var i=0; i<this.nbuckets; i++) {
      var idx = (i + this.idx) % this.nbuckets;
      cb(this._buckets[idx], this._syncs[idx], floor, idx, i);
      floor -= this.per;
    }
  }

  function tick(now) {
    now = now || NOW();
    var per = this.per;

    if (now < this.nextFloor) return;

    var nowFloor = this.getFloor(now);
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
    this.syncer = this.syncer || new Syncer(redis);
    this.syncer.addCounter(this);
    return this.syncer;
  }

  function sync(redis, cb) {
    this.getSyncer().sync(cb);
  }

  function push(cb) {
    this.getSyncer().push(cb);
  }

  function pull(cb) {
    this.getSyncer().pull(cb);
  }

  function inc(key, n) {
    this.tick();

    n = typeof n == 'number' ? n : 1;

    var curr = this._buckets[this.idx];
    curr[key] = (curr[key] || 0) + n;
  }

  function getFloor(time) {
    time = time || NOW();
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
    idx = (this.idx + idx) % this.nbuckets;
    return (this._buckets[idx][key] || 0) + (this._syncs[idx][key] || 0)
  }

}

