export class Counter {
  function initialize() {
    this._data = {};
    this._sync = {};
  }

  function inc(key, n) {
    var data = this._data;
    data[key] = (data[key] || 0) + (n || 1);
    if (!(key in this._sync)) this._sync[key] = 0;
  }

  function sync(redis, namespace, cb) {
    this.pushData(redis, namespace, #(err) {
      if (err && cb) return cb(err);
      self.pullData(redis, namespace, cb);
    });
  }

  function pushData(redis, namespace, cb) {
    var multi = [];
    this.setupRedisMulti(multi, namespace);
    redis.multi(multi).exec(#(err) { if (cb) cb(err); });
  }

  function pullData(redis, namespace, cb) {
    redis.hgetall(namespace, #(err, hash) {
      if (err) return cb(err);
      for (var k in hash) self.replaceSync(k, parseInt(hash[k]));
      if (cb) cb(null);
    });
  }

  function setupRedisMulti(multi, redisKey) {
    var data = this._data;
    var keys = [];

    for (var k in data) {
      this._sync[k] = this.get(k);
      multi.push([ 'HINCRBY', redisKey, k, data[k] ]);
    }

    this._data = {};
  }

  function getData() {
    var ret = {};
    for (var k in this._sync) ret[k] = this.get(k);
    return ret;
  }

  function replaceSync(key, val) {
    var old = this._sync[key] || 0;
    this._sync[key] = val;
    return val - old;
  }

  function get(key) {
    return (this._data[key] || 0) + (this._sync[key] || 0);
  }
}
