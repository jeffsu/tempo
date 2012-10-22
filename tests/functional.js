var tempo = require('../');
var redis = require('redis').createClient();
module.exports['test sync'] = function (test, assert) {
  var syncer   = new tempo.Syncer(redis);
  var options  = { per: 100, buckets: 5, namespace: 'foo' + (new Date).getTime() };

  var counter1 = syncer.counter(options);
  var counter2 = syncer.counter(options);

  later(function () {
    counter1.inc('foo');
    counter2.inc('bar');
  });

  later(function () {
    counter2.inc('foo');
  });

  later(function () {
    syncer.sync();
  });

  later(function () {
    assert.equal(counter1.getCount('foo'), 2);
    redis.end();
    test.finish();
  });

};

var timing = 0;
function later(cb) {
  setTimeout(cb, timing += 100);
}
