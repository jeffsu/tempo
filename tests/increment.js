var tempo = require('../');

exports['test incrementing'] = function (test, assert) {
  var counter = new tempo.Counter({ per: 100, buckets: 5 });
  counter.inc('hello');
  assert.equal(counter.getCount('hello'), 1);

  counter.inc('hello', 2);
  assert.equal(counter.getCount('hello'), 3);
  assert.equal(counter.getIdxVal('hello', 0), 3);
  test.finish();
};

exports['test timed incrementing'] = function (test, assert) {
  var counter = new tempo.Counter({ per: 100, buckets: 5 });
  counter.inc('hello');
  assert.equal(counter.getCount('hello'), 1);

  counter.inc('hello', 2);
  assert.equal(counter.getCount('hello'), 3);
  assert.equal(counter.getIdxVal('hello', 0), 3);

  setTimeout(function () { 
    assert.equal(counter.getIdxVal('hello', 0), 0);
    assert.equal(counter.getIdxVal('hello', 1), 3);
  }, 100);

  setTimeout(function () { 
    assert.equal(counter.getIdxVal('hello', 1), 0);
    assert.equal(counter.getIdxVal('hello', 2), 3);
  }, 200);

  setTimeout(function () { 
    assert.equal(counter.getCount('hello'), 3);
  }, 400);


  setTimeout(function () { 
    assert.equal(counter.getCount('hello'), 0);
    test.finish();
  }, 600);
};
