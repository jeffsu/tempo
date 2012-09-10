var tempo = require('../lib/tempo');
var counter = new tempo.TimedCounter({ per: 100, buckets: 20 });

setInterval(function () {
  for (var i=0; i<10000; i++) counter.inc(i);
}, 100);
