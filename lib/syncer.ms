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

  function stop() {
    this.isRunning = false;
  }

  function start(interval) {
    this.isRunning = true;
    var run  = #{ if (self.isRunning) self.sync(beat) };
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
      if (err) {
        if (cb) cb(err);
        return;
      }

      foreach (var h in handlers) h(results);
      if (cb) cb(err);
    });
  }

  function push(cb) {
    var multi = [];
    foreach (var c in this.counters) this.pushMulti(c, multi);
    this.redis.multi(multi).exec(#(err) { if (cb) cb(err); });
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
    counter.tick();
    var floor = counter.floor;
    counter._forEach(#(bucket, sync, time, id, i) {
      for (var k in bucket) {
        sync[k] = (sync[k] || 0) + bucket[k];
        var key = counter.prefix + time;
        multi.push([ 'HINCRBY', key, k, bucket[k] ]);
        multi.push([ 'PEXPIREAT', key, time + counter.expireTime ]);

        bucket[k] = 0;
      }
    });
  }

  function pullMulti(counter, multi, handlers) {
    counter.tick();
    var startIdx = multi.length;
    var floor    = counter.floor;

    counter._forEach(#(bucket, sync, time) {
      var key = counter.prefix + time;
      multi.push([ 'HGETALL', key ]);
    });

    handlers.push(#(results) {
      var cursor = startIdx;
      counter._forEach(#(bucket, sync, time) {
        if (time == floor) {
          var hash = results[cursor];
          if (hash) 
            for (var k in hash) sync[k] = parseFloat(hash[k]);

          floor -= counter.per;
        }

        cursor++;
      });
    });
  }
}
