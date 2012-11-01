var tempo = require('../');

exports['test pushMulti'] = function (test) {
  var syncer = new tempo.Syncer();
  var counter = syncer.counter({ per: 100, buckets: 5, namespace: 'foo' });
  counter.inc('hello');

  var multi = [];
  syncer.pushMulti(counter, multi);

  var floor = counter.floor;
  test.deepEqual([ 'HINCRBY',   'foo:' + floor, 'hello', 1 ], multi[0]);
  test.deepEqual([ 'PEXPIREAT', 'foo:' + floor, floor + counter.expireTime ], multi[1]);
  test.done();
};

exports['test pullMulti'] = function (test) {
  var syncer = new tempo.Syncer();
  var counter = syncer.counter({ per: 100, buckets: 5, namespace: 'foo' });
  counter.inc('hello');

  var multi = [];
  var handlers = [];
  var results  = [ { hello: 10 } ];

  syncer.pullMulti(counter, multi, handlers);
  handlers.forEach(function (h) { h(results) });
  test.equal(counter.getIdxVal('hello', 0), 11);
  test.done();
};

exports['test pullMulti async'] = function (test) {
  var syncer = new tempo.Syncer();
  var counter = syncer.counter({ per: 100, buckets: 5, namespace: 'foo' });
  counter.inc('hello');

  var multi = [];
  var handlers = [];
  var results  = [ { hello: 10 } ];

  syncer.pullMulti(counter, multi, handlers);
  setTimeout(function () {
    handlers.forEach(function (h) { h(results) });
    test.equal(counter.getIdxVal('hello', 0), 0);
    test.equal(counter.getIdxVal('hello', 1), 11);
  }, 100);

  setTimeout(function () {
    test.equal(counter.getIdxVal('hello', 0), 0);
    test.equal(counter.getIdxVal('hello', 2), 11);
    test.done();
  }, 200);
};
