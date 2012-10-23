# Tempo

Scalable time-based counters that meant logging, graphing and providing a realtime statistics. All features in tempo are meant to have a constant size memory footprint defined by configuration.

For a quick example, please look at examples/simple-use-case.js

# Features

  1. simple counters that sync over redis using a hash structure
  1. counters that keep track of historical data in buckets
  1. syncing with redis for aggregation on multiple servers
  1. throttling


# Use Case

Lets say you are running a website and want to know in realtime where people are visiting.

```javascript

  var redis = require('redis').createClient();
  var tempo = require('tempo');

  // create middleware to track counts
  // create time counter, increment and sync
  var min = tempo.min();

  app.use(function (req, res, next) {
    // the '1' is unnecessary because increment defaults to '1'
    min.inc('requests', 1); 
    if (min.getCount('requests') > 1000) return next('throttled');
    next();
  })

  function showTotalRequestsInPastMin() {
    min.getKeys().forEach(function (k) { console.log(k, min.getCount(k)) });
  }

  function showRequestsOverTime() {
    min.eachCount('requests', function (count, time) {
      console.log("Requsts at " + (new Date(time)).toString() + ': ' + count); 
    });

    console.log(tempo.getCount('requests') + ' request(s) made in the last minute'); 
  }

```

# Counter

The tempo TimedCounter class allows you to create a datastore object and keep
data in memory.

## Instance methods

### var counter = new tempo.Counter(options)

  1. options hash
    1. per: milliseconds per bucket
    1. buckets: number of buckets
    1. timeout (optional): Time to live. Mainly for redis syncing. Defaults to (per*bucket)+per*2

Example for keeping data up to an hour of history:

```javascript
var tempo = require('tempo');
var ds = new tempo.TimedCounter({ per: 60000, buckets: 60 });
```

### counter.inc(key, [n]); O(1)

  1. key: entity name
  1. n (optional, defaults to 1): a number to increment by.

Keeping track of how many times a user has logged in in the past hour:
```javascript
  var ds = require('tempo').hour();
  ds.inc(userId);
```

### counter.getHistory(key); O(n)

   1. key: entity name

Grabbing logged in counts:

```javascript
  var history = ds.getHistory(userId);
```

Returns an array of counts (per bucket)


### counter.sync([callback]) O(nb)

  1. redis client  
  1. prefix/namespace for the key to store in redis
    * tempo's keys will look something like "<namespace>:<timestamp>"
  1. O(nt) where n is the number of keys and b is the number of buckets

```javascript
  counter.sync(redis, 'web-stats', callback);
```

### counter.getKeys(); O(nb)

returns and array of all the keys in the counter
O(nt) where n is the number of keys and b is the number of buckets

### counter.eachCount(key1, key2, ... [ callback ])

Runs a callback against every bucket in the counter with arguments (see examples below):

```
counter.eachCount('key1', 'key2', function (keyCount1, keyCount2, time) {
  console.log('key1', keyCount1, ' at ' + (new Date(time)).toString());
  console.log('key2', keyCount2, ' at ' + (new Date(time)).toString());
});


# Syncer

```javascript
var tempo = require('tempo');
var syncer = new tempo.Syncer(redisClient);
```

## Instance methods

### syncer.addCounter(counter);

Adds a counter to the list of counters to sync at once

### var counter = syncer.counter(options)

Shortcut to instantiate counter and add it

### syncer.sync([ callback ])

Syncs all counters to redis (push and pull)

### syner.push([ callback ])

Pushes data  to redis

### syncer.pull([ callback ])

Pulls data from redis

### syncer.start(type, interval)

Starts running a type of sync at given intervals between syncs

```javascript
syncer.start('push', 3000) // push to redis every 3 seconds
```
