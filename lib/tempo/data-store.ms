export class DataStore {

  function initialize(config) {
    this.per      = config.per;
    this.nBuckets = config.buckets;
    this.totalTime = this.per * this.nBuckets;

    this.sync    = {};
    this.history = {};
  }

  function increment(key, attr, n) {
    var bucket = this.getBucket(this.now(), this.history);
    var item   = bucket.data[key] = bucket.data[key] || {};
    return item[attr] = (item[attr] || 0) + (n === undefined ? 1 : n);
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

    for (var i=0; i<this.nBuckets; i++) {
      var time = floor - (i * this.per);
      ret.push([ time, this.getVal(key, attr, time) ])
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
