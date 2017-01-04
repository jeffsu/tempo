var tempo = require('../');
var per = 500;

exports['test incrementing'] = function (test) {
  var counter = new tempo.Counter({ per: per, buckets: 5 });
  counter.inc('hello');
  test.equal(counter.getCount('hello'), 1);

  counter.inc('hello', 2);
  test.equal(counter.getCount('hello'), 3);
  test.equal(counter.getIdxVal('hello', 0), 3);
  test.done();
};

exports['test timed incrementing'] = function (test) {
  var counter = new tempo.Counter({ per: per, buckets: 5 });
  counter.inc('hello');
  test.equal(counter.getCount('hello'), 1);

  counter.inc('hello', 2);
  test.equal(counter.getCount('hello'), 3);
  test.equal(counter.getIdxVal('hello', 0), 3);

  setTimeout(function () { 
    test.equal(counter.getIdxVal('hello', 0), 3);
    test.equal(counter.getIdxVal('hello', 1), 0);
    counter.inc('hello', 2);
  }, per);

  setTimeout(function () { 
    test.equal(counter.getIdxVal('hello', 0), 3);
    test.equal(counter.getIdxVal('hello', 4), 2);
    test.equal(counter.getCount('hello'), 5);
  }, 3 * per);

  setTimeout(function () { 
    test.equal(counter.getCount('hello'), 0);
    test.done();
  }, 6 * per);
};
