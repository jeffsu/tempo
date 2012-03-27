var counters = require('../lib/counters');
var assert = require('assert');

var PER = 100;
var N   = 5;

var ds = new counters.DataStore({ per: PER, buckets: N });
ds.increment('test', 'count');
assert.equal(1, ds.getVal('test', 'count'));
var firstTime = counters.now();

setTimeout(#{
  ds.increment('test', 'count');
  assert.equal(1, ds.getVal('test', 'count', counters.now()));
  assert.equal(1, ds.getVal('test', 'count', firstTime));
  assert.equal(2, ds.getTotal('test', 'count'));
}, PER);
