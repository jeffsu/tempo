var tempo = require('../');

exports['test iterator'] = function (test) {
  var counter = new tempo.Counter({ per: 100, buckets: 5 });
  counter.inc('hello');
  counter.inc('goodbye', 2);

  var i = 0;
  counter.eachCount('hello', function (count, time) {
    if (i++ == 0) test.equal(count, 1);
  });

  i = 0;
  setTimeout(function () {
    counter.inc('hello');
    counter.eachCount('hello', function (count, time) {
      if (i == 0) test.equal(count, 1);
      if (i == 2) test.equal(count, 1);
      i++;
    });
  }, 200);

  setTimeout(function () {
    counter.eachCount('hello', 'goodbye', function (count1, count2, time) {
      if (i == 3) test.equal(count1, 1);
      if (i == 3) test.equal(count2, 2);
      i++;
    });
    test.done();
  }, 300);
};


