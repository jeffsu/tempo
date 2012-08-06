export class Counter {
  function initialize() {
    this._data = {};
    this._sync = {};
  }

  function inc(key, n) {
    var data = this._data;
    data[key] = (data[key] || 0) + (n || 1);
    if (!(k in this._sync)) this._sync[k] = 0;
  }

  function sync(redis, namespace, cb) {
    this.pushData(redis, namespace, #(err) {
      if (err) return cb(err);
      self.pullData(redis, namespace);
    });
  }

  function pushData(redis, namespace, cb) {
    var multi = redis.multi();
    this.setupRedisMulti(multi, namespace);
    multi.exec(#(err) { cb(err); });
  }

  function pullData(redis, namespace, cb) {
    redis.hgetall(namespace, #(err, hash) {
      if (err) return cb(err);
      for (var k in hash) this.replaceSync(k, parseInt(hash[k]));
      cb(null);
    });
  }

  function setupRedisMulti(multi, redisKey) {
    var data = this._data;
    var keys = [];

    for (var k in data) {
      this._sync[k] = this.get(key);
      multi.hincrby(redisKey, k, data);
    }

    this._data = {};
  }

  function getData() {
    var ret = {};
    for (var k in this._sync) ret[k] = this.get(k);
  }

  function replaceSync(key, val) {
    var old = this._sync[key] || 0;
    this._sync[key] = old + val;
    return val - old;
  }

  function get(key) {
    return (this._data[key] || 0) + (this._sync[key] || 0);
  }
}
