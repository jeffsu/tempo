var tempo = require('../');

exports['test pushMulti'] = function (test, assert) {
  var syncer = new tempo.Syncer();
  var counter = syncer.counter({ per: 100, buckets: 5, namespace: 'foo' });
  counter.inc('hello');

  var multi = [];
  syncer.pushMulti(counter, multi);

  var floor = counter.floor;
  assert.deepEqual([ 'HINCRBY',   'foo:' + floor, 'hello', 1 ], multi[0]);
  assert.deepEqual([ 'PEXPIREAT', 'foo:' + floor, floor + counter.expireTime ], multi[1]);
  test.finish();
};

exports['test pullMulti'] = function (test, assert) {
  var syncer = new tempo.Syncer();
  var counter = syncer.counter({ per: 100, buckets: 5, namespace: 'foo' });
  counter.inc('hello');

  var multi = [];
  var handlers = [];
  var results  = [ { hello: 10 } ];

  syncer.pullMulti(counter, multi, handlers);
  handlers.forEach(function (h) { h(results) });
  assert.equal(counter.getIdxVal('hello', 0), 11);
  test.finish();
};

exports['test pullMulti async'] = function (test, assert) {
  var syncer = new tempo.Syncer();
  var counter = syncer.counter({ per: 100, buckets: 5, namespace: 'foo' });
  counter.inc('hello');

  var multi = [];
  var handlers = [];
  var results  = [ { hello: 10 } ];

  syncer.pullMulti(counter, multi, handlers);
  setTimeout(function () {
    handlers.forEach(function (h) { h(results) });
    assert.equal(counter.getIdxVal('hello', 0), 0);
    assert.equal(counter.getIdxVal('hello', 1), 11);
  }, 100);

  setTimeout(function () {
    assert.equal(counter.getIdxVal('hello', 0), 0);
    assert.equal(counter.getIdxVal('hello', 2), 11);
    test.finish();
  }, 200);
};
