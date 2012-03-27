var tempo = require('../lib/tempo');
var assert = require('assert');

var PER = 100;
var N   = 5;

var avg = new tempo.Average({ per: PER, buckets: N });

avg.add(20);
avg.add(10);

var firstTime = tempo.now();
assert.equal(15, avg.getAverage(firstTime));

setTimeout(#{
  assert.equal(null, avg.getAverage(tempo.now()));
  assert.equal(15, avg.getAverage(firstTime));
}, PER);

setTimeout(#{
  avg.add(30);

  assert.equal(30, avg.getAverage(tempo.now()));
  assert.equal(15, avg.getAverage(firstTime));
  assert.equal(20, avg.getAverage());

  var started = avg.getHistory()[1]; // [ time, average, total, count ]
  var latest  = avg.getHistory()[4];

  assert.equal(15, started[1]);
  assert.equal(30, started[2]);
  assert.equal(2,  started[3]);

  assert.equal(30, latest[1]);
  assert.equal(30, latest[2]);
  assert.equal(1,  latest[3]);

}, PER * 3);
