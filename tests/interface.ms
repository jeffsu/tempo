var tempo  = require('../');
var per = 200;
var redis = require('redis').createClient();

function startSyncing(counter, time) {
  var sync = #{ counter.sync(redis, beat, { quick: true }); }
  var beat = #{ setTimeout(sync, time); }

  counter.sync(redis, beat);
}

function initCounter() {
  return new tempo.Counter({
    per: per,
    buckets: 12
  });
}

exports['test offset'] = function (test) {
  var counter1 = initCounter();
  var counter2 = initCounter();
  var counter3 = initCounter();

  startSyncing(counter1, 100);
  startSyncing(counter2, 100);
  startSyncing(counter3, 100);

  counter1.increment('hello');
  counter2.increment('hello');
  counter3.increment('hello');

  test.equal(counter1.getCount('hello'), 1);
  test.equal(counter2.getCount('hello'), 1);
  test.equal(counter3.getCount('hello'), 1);

  setTimeout(function () {
    test.equal(counter1.getCount('hello'), 3);
    test.equal(counter2.getCount('hello'), 3);
    test.equal(counter3.getCount('hello'), 3);

    counter1.increment('hello');
    counter2.increment('hello');
    counter3.increment('hello');

    test.equal(counter1.getCount('hello'), 4);
    test.equal(counter2.getCount('hello'), 4);
    test.equal(counter3.getCount('hello'), 4);
  }, per * 3);

  setTimeout(function () {
    test.equal(counter1.getCount('hello'), 6);
    test.equal(counter2.getCount('hello'), 6);
    test.equal(counter3.getCount('hello'), 6);

    var bucket = counter1._buckets[counter1.idx - 3];
    bucket['hello'] = bucket['hello'] || 0
    bucket['hello'] += 1

    test.equal(counter1.getCount('hello'), 7);
  }, per * 3 * 2);

  setTimeout(function () {
    // because only sync recent 2 buckets
    // so new increment won't be kept
    test.equal(counter1.getCount('hello'), 6);
    test.equal(counter2.getCount('hello'), 6);
    test.equal(counter3.getCount('hello'), 6);

    redis.quit();
    test.done();
  }, per * 3 * 3);
}
