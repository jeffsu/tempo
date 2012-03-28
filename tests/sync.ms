var redis = require('redis');
var tempo = require('../lib/tempo');
var assert = require('assert');

var client = redis.createClient();

var config = { per: 500, buckets: 5 };

var ds1 = new tempo.DataStore(config);
ds1.increment('foo', 'bar');
ds1.redisSync(client);

var ds2 = new tempo.DataStore(config);
ds2.increment('foo', 'bar');

assert.equal(1, ds2.getVal('foo', 'bar'));
assert.equal(1, ds2.getTotal('foo', 'bar'));

ds2.redisSync(client);


ds2.on('sync', #{
  console.log('synced');
  assert.equal(2, ds2.getTotal('foo', 'bar'));
});
