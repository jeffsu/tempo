var tempo = require('../lib/tempo');
var redis = require('redis').createClient();
var assert = require('assert');

var PER = 100;
var N   = 5;
var namespace = 'test-' + Math.floor(Math.random() * 100000)
console.log('using namespace: ' + namespace);

var ds = new tempo.DataStore({ per: PER, buckets: N });
ds.increment('count', 5);
assert.equal(5, ds.getCount('count'));
ds.increment('count');
assert.equal(6, ds.getCount('count'));
ds.sync(redis, namespace);
