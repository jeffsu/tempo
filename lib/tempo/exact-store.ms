var DataStore = require('./data-store');
var time      = require('./time');

function getDate(time) {
  return time ? new Date(time) : new Date();
}

var FLOORS = {
  MONTH: #(time) {
    var date = getDate(time);
    return (new Date(date.getUTCFullYear(), date.getUTCMonth(), 0, 0, 0, 0, 0)).getTime();
  },

  DAY: #(time) {
    var date = getDate(time);
    return (new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDay(), 0, 0, 0, 0)).getTime();
  },

  TEST: #(time) {
    time = time || this.now();
    return time - (time % 1000);
  }
};

var GET_TIMES = {
  DAY: #(time) {
    var date = getDate(time);
    var ret = [ date.getTime() ];
    for (var i=1; i<this.nBuckets; i++) {
      date.setDate(date.getUTCDate() - 1);
      ret.push(date.getTime());
    }

    return ret;
  },

  MONTH: #(time) {
    var date = getDate(time);
    var ret = [ date.getTime() ];
    for (var i=1; i<this.nBuckets; i++) {
      date.setMonth(date.getMonth() - 1);
      ret.push(date.getTime());
    }

    return ret;
  },

  TEST: #(time) {
    var date = getDate(time);
    var ret = [ date.getTime() ];
    for (var i=1; i<this.nBuckets; i++) {
      date.setMonth(date.getSeconds() - 1);
      ret.push(date.getTime());
    }

    return ret;
  }
}


class ExactStore extends DataStore {
  function initialize(config) {
    var newConfig = {};
    newConfig.__proto__ = config;
    var on = newConfig.on = newConfig.on.upCase();

    newConfig.per     = time[on];
    newConfig.buckets = config.buckets;

    this.getFloor = FLOORS[on];
    this.getTimes = FLOORS[on];

    this.$super(newConfig);
  }
}
