var tempo  = require('../');
var per = 200;

exports['test offset'] = function (test) {
  var redis  = require('redis').createClient();

  var syncer = new tempo.Syncer(redis);

  var counter1 = syncer.counter({ per: per, buckets: 8, namespace: 'foo' });
  counter1.inc('hello');

  var counter2 = syncer.counter({ per: per, buckets: 8, namespace: 'foo', offset: 2 });

  setTimeout(#{
    test.equal(counter1.getCount('hello'), 1);
    test.equal(counter2.getCount('hello'), 0);
  }, per);


  setTimeout(#{
    syncer.sync();
  }, 3 * per);

  setTimeout(#{
    test.equal(counter1.getCount('hello'), 1);
    test.equal(counter2.getCount('hello'), 1);
  }, 4 * per);

  setTimeout(#{
    redis.quit();
    test.done();
  }, 6 * per);
};
