var tempo = require('../lib/tempo');
var counter = new tempo.TimedCounter({ per: 10, buckets: 200 });

setInterval(function () {
  for (var i=0; i<10000; i++) counter.inc(i);
  var foo = counter.getHistory(0);
}, 5);

var prev = process.memoryUsage();
setInterval(function () {
  var now = process.memoryUsage();
  for (var k in now) 
    console.log(k + ': ' + (now[k] - prev[k]));
  prev = now;
}, 10000);
