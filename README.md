# Tempo

Scalable time-based counters that meant logging, graphing and providing a realtime statistics. All features in tempo are meant to have a constant size memory footprint defined by configuration.

For a quick example, please look at examples/simple-use-case.js

# Features

  1. preset counters for: min, hour, day, week
  1. syncing with redis for aggregation on multiple servers
  1. sparse logging: keep a defined number of random entries in a log

# Use Case

Lets say you are running a website and want to know in realtime where people are visiting.

```

  var tempo = require('tempo').min();

  app.use(function (req, res, next) {
    // the '1' is unnecessary because increment defaults to '1'
    tempo.increment('website', 'requests', 1); 
    next();
  })

  function showRequestsOverTime() {
    var history = tempo.getHistory('website', 'requests');

    var total = 0;
    for (var i=0; i<history.length; i++) {
      var bucket = history[i];
      var time = bucket[0];
      var n    = bucket[1];
    }

    console.log(tempo.getTotal('website', 'requests') + ' request(s) made in the last minute'); 
  }

```

# DataStore

The tempo DataStore class allows you to create a datastore object and keep
data in memory.

## Instance methods

### var datastore = new tempo.DataStore(options)

  1. options:
    1. per: milliseconds per bucket
    1. buckets: number of buckets

Example for keeping data up to an hour of history:

```
var tempo = require('tempo');
var ds = new tempo.DataStore({ per: 60000, buckets: 60 });
```

### datastore.increment(key, attr, n);

  1. key: an entity id
  1. attr: an attribute of the entity
  1. n (optional, defaults to 1): a number to increment by.

Keeping track of how many times a user has logged in in the past hour:
```
  var ds = require('tempo').hour();
  ds.increment(userId, 'logged-in', 1);
```

### datastore.getHistory(key, attr1, attr2, ...)

   1. key: entity id
   1. attrName: attribute names

Grabbing logged in counts:

```
  var history = ds.getHistory(userId, 'logged-in');
```

Returns an array of arrays:

```
  [ [ <timestampOfBucket>, <loggedInCount> ],
    [ <timestampOfBucket>, <loggedInCount> ],
    [ <timestampOfBucket>, <loggedInCount> ] ]
```

### datastore.sync(prefix, redis, interval)

Returns intervalId

This allows you to setup the datastore to save data to redis.  Just like
the datastore, redis will expire data passed the history limit.  This will
also work in conjunction with multiple servers so they will all sync up
together.

Sync to redis every 10 seconds.
```
  var id = datastore.sync('web-stats', redis, 10000);
  // to stop: stopInterval(id);
```
