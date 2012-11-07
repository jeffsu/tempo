var tempo = require('../');
var redis = require('redis').createClient();

var counter1 = new tempo.Counter({ name: 'c1', buckets: 5, per: 100, namespace: 'testing' });
var counter2 = new tempo.Counter({ name: 'c2', buckets: 5, per: 100, namespace: 'testing', offset: 1 });

setInterval(function () { counter1.inc('hello'); }, 5);

setInterval(function () {
  counter1.push(redis, function () { console.log("counter1 sync") });
  counter2.pull(redis, function () { console.log("counter2 sync") });

  console.log('----------- Counter1:' + counter1.getCount('hello'));
  console.log(counter1.toTable().toString());
  console.log('----------- Counter2:' + counter2.getCount('hello'));
  console.log(counter2.toTable().toString());
}, 100);
