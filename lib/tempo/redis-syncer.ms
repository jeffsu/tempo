export class RedisSyncer {
  include $m.EventEmitter;

  function initialize(prefix, redis, ds) {
    this.prefix = prefix ? prefix + ':' : ''; 
    this.redis  = redis;
    this.ds     = ds;
  }

  function sync() {
    var ds     = this.ds;
    var prefix = this.prefix;

    var commands = [], expires = [], redisKeys = [], lookups = [];

    for (var time in ds.history) {
      var items = ds.history[time].items;

      var keys = [];
      for (var key in items.data) {
        keys.push(key);
        var item = items(key);

        for (var attr in item) {
          var val      = item[attr];
          var redisKey = prefix + 'data:' + key + ':' + time;
          redisKeys.push([ time, key, attr ]);
          commands.push([ 'HINCRBY', redisKey, attr, val ]);
          expires.push([ 'EXPIREAT', redisKey, time + ds.totalTime ]);
        }
      }

      if (keys.length) {
        var key = prefix + "keys:" + time;
        keys.unshift(key);
        keys.unshift("SADD");
        expires.push(keys);
        expires.push([ 'EXPIREAT', key, time + ds.totalTime ]);
      }
    }

    foreach (var exp in expires) {
      commands.push(exp);
    }

    var multi = this.redis.multi(commands);
    multi.exec(#(err, results) {
      if (err) return;
      foreach (var rkey:i in redisKeys) {
        var time = rkey[0];
        var key  = rkey[1];
        var attr = rkey[2];

        var item = ds.getBucket(time, ds.syncHistory).items(key);
        item[attr] = results[i];
      }
      self.emit('sync');
    });

    ds.flushHistory();
  }
}
