var redis = require('redis');
var tempo = require('../lib/tempo');
var assert = require('assert');

var client = redis.createClient();

var config = { per: 2000, buckets: 5 };
var namespace = 'test-' + Math.floor(Math.random() * 100000)

var ds1 = new tempo.DataStore(config);
ds1.increment('foo');

var ds2 = new tempo.DataStore(config);
ds2.increment('foo');

var ds3 = new tempo.DataStore(config);
ds3.increment('foo');

// sanity
assert.equal(1, ds1.getCount('foo'));
assert.equal(1, ds2.getCount('foo'));
assert.equal(1, ds3.getCount('foo'));

// Sync test
ds1.sync(client, namespace);
ds2.sync(client, namespace);
ds3.sync(client, namespace);

setTimeout(#{
  console.log('running sync tests');
  assert.equal(3, ds1.getCount('foo'));
  assert.equal(3, ds2.getCount('foo'));
  assert.equal(3, ds3.getCount('foo'));
}, 500);

