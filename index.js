require('mochiscript');

var time = require('./lib/time');

var ex = module.exports = {
  Counter:      require('./lib/counter'),
  TimedCounter: require('./lib/counter'),
  Syncer:       require('./lib/syncer'),
  SparseLogger: require('./lib/sparse-logger')
};

ex.MIN  = { per: time.SEC * 5,  buckets: 12 };
ex.DAY  = { per: time.HOUR,     buckets: 24 };
ex.HOUR = { per: time.MIN * 5,  buckets: 12 };
ex.WEEK = { per: time.HOUR * 6, buckets: 7 * 4 };

ex.min  = function (namespace) { 
  ex.MIN.namespace = namespace || "";
  return new ex.Counter(ex.MIN) 
};

ex.hour = function (namespace) { 
  ex.HOUR.namespace = namespace || "";
  return new ex.Counter(ex.HOUR) 
};

ex.day  = function (namespace) { 
  ex.DAY.namespace = namespace || "";
  return new ex.Counter(ex.DAY) 
};

ex.week = function (namespace) { 
  ex.WEEK.namespace = namespace || "";
  return new ex.Counter(ex.WEEK) 
};
