var Counter   = require('../lib/tempo/counter');
var assert    = require('assert');
var redis     = require('redis').createClient();
var namespace = require('./utils').rand();

var c = new Counter();
var c2 = new Counter();

c.inc('hello');
c.inc('world', 5);

assert.equal(c.get('hello'), 1);
assert.equal(c.get('world'), 5);

c.sync(redis, namespace, #(err) {
  assert.ok(!err);
  redis.hgetall(namespace, #(err, all) {
    assert.equal(all['hello'], 1);
    assert.equal(all['world'], 5);
  });
});

c2.sync(redis, namespace, #(err) {
  assert.equal(c2.get('hello'), 1);
  assert.equal(c2.get('world'), 5);
});

redis.expire(namespace, 3600);
