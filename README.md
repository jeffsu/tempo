# Tempo

Scalable time-based counters that meant logging, graphing and providing a realtime statistics. All features in tempo are meant to have a constant size memory footprint defined by configuration.

For a quick example, please look at examples/simple-use-case.js

# Features

  1. simple counters that sync over redis using a hash structure
  1. counters that keep track of historical data in buckets
  1. syncing with redis for aggregation on multiple servers
  1. sparse logging: keep a defined number of random entries in a log


# Use Case

Lets say you are running a website and want to know in realtime where people are visiting.

```

  var redis = require('redis').createClient();
  var tempo = require('tempo');

  // create middleware to track counts
  // create time counter, increment and sync
  var min = tempo.min();

  app.use(function (req, res, next) {
    // the '1' is unnecessary because increment defaults to '1'
    min.inc('requests', 1); 
    next();
  })

  function showRequestsOverTime() {
    var history = tempo.getHistory('requests');
    var times   = tempo.getTimes();

    for (var i=0; i<history.length; i++) {
      console.log("Requsts at " + (new Date(times[i])).toString() + ': ' + history[i]); 
    }

    console.log(tempo.getCount('requests') + ' request(s) made in the last minute'); 
  }

```

# TimedCounter

The tempo TimedCounter class allows you to create a datastore object and keep
data in memory.

## Instance methods

### var timedCounter = new tempo.TimedCounter(options)

  1. options hash
    1. per: milliseconds per bucket
    1. buckets: number of buckets
    1. timeout (optional): ttl pass expiration time

Example for keeping data up to an hour of history:

```
var tempo = require('tempo');
var ds = new tempo.TimedCounter({ per: 60000, buckets: 60 });
```

### timedCounter.incr(key, n);

  1. key: entity name
  1. n (optional, defaults to 1): a number to increment by.

Keeping track of how many times a user has logged in in the past hour:
```
  var ds = require('tempo').hour();
  ds.increment(userId);
```

### timedCounter.getHistory(key, attr1, attr2, ...)

   1. key: entity name

Grabbing logged in counts:

```
  var history = ds.getHistory(userId);
```

Returns an array of counts (per bucket)


### timedCounter.sync(redis, namespace)

  1. redis client  
  1. prefix/namespace for the key to store in redis
    * tempo's keys will look something like "<namespace>:<timestamp>"

```
  timedCounter.sync(redis, 'web-stats', callback);
```
