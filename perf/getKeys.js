var tempo = require('../');
var counter = new tempo.Counter({ per: 10, buckets: 100 });

var COUNT = 300;
var MB    = 1024 * 1024;

for (var i=0; i<COUNT; i++) counter.inc('hello' + i);

require('./utils').run('getKeys for 300 keys * 100 times', function () {
  for (var i=0; i<100; i++) counter.getKeys();
});
