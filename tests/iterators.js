var tempo = require('../');

exports['test iterator'] = function (test, assert) {
  var counter = new tempo.Counter({ per: 100, buckets: 5 });
  counter.inc('hello');
  counter.inc('goodbye', 2);

  var i = 0;
  counter.eachCount('hello', function (count, time) {
    if (i++ == 0) assert.equal(count, 1);
  });

  i = 0;
  setTimeout(function () {
    counter.inc('hello');
    counter.eachCount('hello', function (count, time) {
      if (i == 0) assert.equal(count, 1);
      if (i == 2) assert.equal(count, 1);
      i++;
    });
  }, 200);

  setTimeout(function () {
    counter.eachCount('hello', 'goodbye', function (count1, count2, time) {
      if (i == 3) assert.equal(count1, 1);
      if (i == 3) assert.equal(count2, 2);
      i++;
    });
    test.finish();
  }, 300);
};


