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
  var per = 500;
  var counter = syncer.counter({ per: per, buckets: 5, namespace: 'foo' });
  counter.inc('hello');

  var multi = [];
  var handlers = [];
  var results  = [ { hello: 10 } ];

  syncer.pullMulti(counter, multi, handlers);

  setTimeout(function () {
    handlers.forEach(function (h) { h(results) });
    test.equal(counter.getIdxVal('hello', 0), 11);
  }, per);

  setTimeout(function () {
    test.equal(counter.getCount('hello'), 11);
    test.done();
  }, 2 * per);
};

exports['test quick sync'] = function (test) {
  var redis = {
    multi: function (multi) {
      test.equal(multi.filter(function (cmd) {
        return cmd[0] == 'HGETALL'
      }).length, 2)
      return {
        exec: function (cb) {
          cb(null, [
            {},
            {},
            { hello: 1 },
            { hello: 2 },
          ]);
        }
      };
    }
  }

  var syncer = new tempo.Syncer(redis);
  var per = 500;
  var counter = syncer.counter({ per: per, buckets: 5, namespace: 'quick' });

  counter.increment('hello')

  setTimeout(function () {
    syncer.sync(function () {
      test.equal(counter.getCount('hello'), 3)
      counter.increment('hello')
      test.equal(counter.getCount('hello'), 4)
      test.equal(counter.getIdxVal('hello', 0), 2)
      test.equal(counter.getIdxVal('hello', 4), 2)
      test.done()
    }, {
      quick: true
    })
  }, per);
}
