var Counter = require('./counter');
export class Syncer {
  function initialize(redis) {
    this.redis = redis;
    this.counters = [];
    this.multi    = [];
  }

  function addCounter(counter) {
    this.counters.push(counter);
  }

  function counter(options) {
    var counter = new Counter(options);
    this.addCounter(counter);
    return counter;
  }

  function start(type, interval) {
    var run  = #{ self[type](beat) };
    var beat = #{ setTimeout(run, interval) };
    run();
  }

  function sync(cb) {
    var multi    = [];
    var handlers = [];

    foreach (var c in this.counters)
      this.pushMulti(c, multi);

    foreach (var c in this.counters)
      this.pullMulti(c, multi, handlers);

    this.redis.multi(multi).exec(#(err, results) {
      if (!err) 
        foreach (var h in handlers) h(results);
      if (cb) cb(err);
    });
  }

  function pull(cb) {
    var multi    = [];
    var handlers = [];

    foreach (var c in this.counters)
      this.pullMulti(c, multi, handlers);

    this.redis.multi(multi).exec(#(err, results) {
      if (!err) 
        foreach (var h in handlers) h(results);
      if (cb) cb(err);
    });
  }

  function pushMulti(counter, multi) {
    var floor = counter.floor;
    counter.forEach(#(bucket, sync, time, id, i) {
      for (var k in bucket) {
        sync[k] = (sync[k] || 0) + bucket[k];
        var key = counter.prefix + time;
        multi.push([ 'HINCRBY', key, k, bucket[k] ]);
        multi.push([ 'PEXPIREAT', key, time + counter.expireTime ]);
      }
    });
  }

  function pullMulti(counter, multi, handlers) {
    var startIdx = multi.length;
    var floor    = counter.floor;

    counter.forEach(#(bucket, sync, time) {
      var key = counter.prefix + ':' + time;
      multi.push([ 'HGETALL', key ]);
    });

    handlers.push(#(results) {
      var cursor = startIdx;
      counter.forEach(#(bucket, sync, time) {
        if (time == floor) {
          var hash = results[cursor];
          for (var k in hash) sync[k] = hash[k];
          floor -= counter.per;
        }

        cursor++;
      });
    });
  }

  function pull(cb) {
    var multi    = [];
    var handlers = [];

    foreach (var c in counter) 
      c.pullMulti(multi, handlers);

    redis.multi(multi).exec(#(err, results) {
      if (err) return cb(err);
      foreach (var h in handlers) h(results);
      cb();
    });
  }
}
