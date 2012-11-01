var tempo = require('../');

exports['test incrementing'] = function (test) {
  var counter = new tempo.Counter({ per: 100, buckets: 5 });
  counter.inc('hello');
  test.equal(counter.getCount('hello'), 1);

  counter.inc('hello', 2);
  test.equal(counter.getCount('hello'), 3);
  test.equal(counter.getIdxVal('hello', 0), 3);
  test.done();
};

exports['test timed incrementing'] = function (test) {
  var counter = new tempo.Counter({ per: 100, buckets: 5 });
  counter.inc('hello');
  test.equal(counter.getCount('hello'), 1);

  counter.inc('hello', 2);
  test.equal(counter.getCount('hello'), 3);
  test.equal(counter.getIdxVal('hello', 0), 3);

  setTimeout(function () { 
    test.equal(counter.getIdxVal('hello', 0), 0);
    test.equal(counter.getIdxVal('hello', 1), 3);
  }, 100);

  setTimeout(function () { 
    test.equal(counter.getIdxVal('hello', 1), 0);
    test.equal(counter.getIdxVal('hello', 2), 3);
  }, 200);

  setTimeout(function () { 
    test.equal(counter.getCount('hello'), 3);
  }, 400);


  setTimeout(function () { 
    test.equal(counter.getCount('hello'), 0);
    test.done();
  }, 600);
};
