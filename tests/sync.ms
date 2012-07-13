var redis = require('redis');
var tempo = require('../lib/tempo');
var assert = require('assert');

var client = redis.createClient();

var config = { per: 2000, buckets: 5 };

var ds1 = new tempo.DataStore(config);
ds1.increment('foo', 'bar');
var now = ds1.now();

var ds2 = new tempo.DataStore(config);
ds2.increment('foo', 'bar');

var ds3 = new tempo.DataStore(config);
ds3.pushOnly = true;
ds3.increment('foo', 'bar');

// sanity
assert.equal(1, ds2.getVal('foo', 'bar'));
assert.equal(1, ds2.getVal('foo', 'bar'));
assert.equal(1, ds3.getVal('foo', 'bar'));

// Sync test
ds1.sync('data', client, 100);
ds2.sync('data', client, 100);
ds3.sync('data', client, 100);

setTimeout(#{
  console.log('running sync tests');
  assert.equal(3, ds1.getTotal('foo', 'bar'));
  assert.equal(3, ds2.getTotal('foo', 'bar'));
  assert.equal(3, ds2.getVal('foo', 'bar', now));

  assert.equal(1, ds3.getTotal('foo', 'bar'));
}, 500);
