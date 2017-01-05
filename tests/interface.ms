var tempo  = require('../');
var per = 200;

function startSyncing(redis, counter, time) {
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

exports['test quick sync'] = function (test) {
  var redis = require('redis').createClient();
  var key = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 5);

  var counter1 = initCounter();
  var counter2 = initCounter();
  var counter3 = initCounter();

  startSyncing(redis, counter1, 100);
  startSyncing(redis, counter2, 100);
  startSyncing(redis, counter3, 100);

  counter1.increment(key);
  counter2.increment(key);
  counter3.increment(key);

  test.equal(counter1.getCount(key), 1);
  test.equal(counter2.getCount(key), 1);
  test.equal(counter3.getCount(key), 1);

  setTimeout(function () {
    test.equal(counter1.getCount(key), 3);
    test.equal(counter2.getCount(key), 3);
    test.equal(counter3.getCount(key), 3);

    counter1.increment(key);
    counter2.increment(key);
    counter3.increment(key);

    test.equal(counter1.getCount(key), 4);
    test.equal(counter2.getCount(key), 4);
    test.equal(counter3.getCount(key), 4);
  }, per * 3);

  setTimeout(function () {
    test.equal(counter1.getCount(key), 6);
    test.equal(counter2.getCount(key), 6);
    test.equal(counter3.getCount(key), 6);

    var bucket = counter1._buckets[counter1.idx - 3];
    bucket[key] = bucket[key] || 0
    bucket[key] += 1

    test.equal(counter1.getCount(key), 7);
  }, per * 3 * 2);

  setTimeout(function () {
    // because only sync recent 2 buckets
    // so new increment won't be kept
    test.equal(counter1.getCount(key), 6);
    test.equal(counter2.getCount(key), 6);
    test.equal(counter3.getCount(key), 6);

    redis.quit();
    test.done();
  }, per * 3 * 3);
}

exports['test quick sync with full load on init'] = function (test) {
  var redis = require('redis').createClient();
  var key = Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 5);

  var counter1 = initCounter();
  var counter2 = initCounter();
  var counter3;

  startSyncing(redis, counter1, 100);
  startSyncing(redis, counter2, 100);

  counter1.increment(key);
  counter2.increment(key);

  test.equal(counter1.getCount(key), 1);
  test.equal(counter2.getCount(key), 1);

  setTimeout(function () {
    test.equal(counter1.getCount(key), 2);
    test.equal(counter2.getCount(key), 2);

    counter3 = initCounter();
    startSyncing(redis, counter3, 100);

    counter1.increment(key);
    counter2.increment(key);
    counter3.increment(key);

    test.equal(counter1.getCount(key), 3);
    test.equal(counter2.getCount(key), 3);
    test.equal(counter3.getCount(key), 1);
  }, per * 3);

  setTimeout(function () {
    test.equal(counter1.getCount(key), 5);
    test.equal(counter2.getCount(key), 5);
    test.equal(counter3.getCount(key), 5);

    redis.quit();
    test.done();
  }, per * 3 * 2);
}
