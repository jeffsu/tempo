var tempo = require('../lib/tempo');
var redis = require('redis').createClient();
var assert = require('assert');

var PER = 100;
var N   = 5;
var namespace = require('./utils').rand();
console.log('using namespace: ' + namespace);

var tc = new tempo.TimedCounter({ per: PER, buckets: N });
tc.increment('count', 5);
assert.equal(5, tc.getCount('count'));
tc.increment('count');
assert.equal(6, tc.getCount('count'));
tc.sync(redis, namespace, #(err) { assert.ok(!err); });
tc.sync(redis, namespace, #(err) { assert.ok(!err); });


var tc2 = new tempo.TimedCounter({ per: PER, buckets: N });
tc2.sync(redis, namespace, #(err) { assert.ok(!err); });

setTimeout(#{ 
  assert.equal(tc.getCount('count'), tc2.getCount('count')) 
  tc.increment('foo-count', 10);
  tc.increment('bar-count', 20);
  assert.ok(tc.getAverageHistory('foo-count', 'bar-count')[0] == 0.5);
}, 2000);
