var redis = require('redis');
var tempo = require('../lib/tempo');
var assert = require('assert');
var namespace = require('./utils').rand();

var client = redis.createClient();

var config = { per: 200, buckets: 5 };

var tc1 = new tempo.TimedCounter(config);
tc1.increment('foo');

var tc2 = new tempo.TimedCounter(config);
tc2.increment('foo');

var tc3 = new tempo.TimedCounter(config);
tc3.increment('foo');

// sanity
assert.equal(1, tc1.getCount('foo'));
assert.equal(1, tc2.getCount('foo'));
assert.equal(1, tc3.getCount('foo'));

setTimeout(#{ 
  tc1.sync(client, namespace);
  tc2.sync(client, namespace);
}, 500);

// Sync test
tc1.sync(client, namespace);
tc2.sync(client, namespace);
tc3.sync(client, namespace);

setTimeout(#{
  console.log('running sync tests');
  assert.equal(3, tc1.getCount('foo'));
  assert.equal(3, tc2.getCount('foo'));
  assert.equal(3, tc3.getCount('foo'));
}, 400);

setTimeout(#{
  console.log('running second sync tests');
  var history = tc2.getHistory('foo');
  assert.equal(history.length, 5);
  assert.deepEqual(history.filter(#{ => $1 > 0 }), [ 3 ]);
  assert.equal(3, tc1.getCount('foo'));
  assert.equal(3, tc2.getCount('foo'));
}, 800);

