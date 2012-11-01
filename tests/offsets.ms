exports['test offset'] = function (test) {
  var tempo  = require('../');
  var redis  = require('redis').createClient();

  var syncer = new tempo.Syncer(redis);

  var counter1 = syncer.counter({ per: 100, buckets: 8, namespace: 'foo' });
  counter1.inc('hello');

  var counter2 = syncer.counter({ per: 100, buckets: 8, namespace: 'foo', offset: 2 });

  setTimeout(#{
    test.equal(counter1.getCount('hello'), 1);
    test.equal(counter2.getCount('hello'), 0);
  }, 100);


  setTimeout(#{
    syncer.sync();
  }, 300);

  setTimeout(#{
    test.equal(counter1.getCount('hello'), 1);
    test.equal(counter2.getCount('hello'), 1);
  }, 400);

  setTimeout(#{
    redis.end();
    test.done();
  }, 600);
};
