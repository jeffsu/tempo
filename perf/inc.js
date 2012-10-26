var tempo = require('../');
var counter = new tempo.Counter({ per: 10, buckets: 100 });

var COUNT = 10000;
var MB    = 1024 * 1024;

var i = 0;
require('./utils').run(COUNT + ' increments', function () {
  for (var i=0; i<COUNT; i++) {
    counter.inc('hello');
  }
});
