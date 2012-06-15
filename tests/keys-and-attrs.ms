var tempo = require('../lib/tempo');
var assert = require('assert');

var PER = 100;
var N   = 5;
var ds = new tempo.DataStore({ per: PER, buckets: N });

setTimeout(#{
  ds.increment('test1', 'count1');
  ds.increment('test1', 'count2');
}, PER);

setTimeout(#{
  ds.increment('test2', 'count1');
  ds.increment('test2', 'count2');

  var firstBucket = ds.getKeys((new Date()).getTime());
  assert.equal(firstBucket.length, 1);

}, PER * 2);

setTimeout(#{
  var keys = ds.getKeys();
  assert.equal(keys.length, 2);

  var attrs = ds.getAttrs('test1');
  assert.equal(attrs.length, 2);

}, PER * 3);

setTimeout(#{
  var keys = ds.getKeys();
  assert.equal(keys.length, 1);

  var attrs = ds.getAttrs('test1');
  assert.equal(attrs.length, 0);
}, PER * 6);

