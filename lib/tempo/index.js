require('mochiscript');

var ex = module.exports;

var time = require('./time');

ex.DataStore   = require('./data-store');
ex.Counter     = require('./counter');
ex.Average     = require('./average');
ex.AttrCounter = require('./attr-counter');
ex.SparseLogger = require('./sparse-logger');
ex.now = function () { return (new Date()).getTime() };

ex.MIN  = { per: time.SEC * 5, buckets: 12 };
ex.DAY  = { per: time.HOUR, buckets: 24 };
ex.HOUR = { per: time.MIN * 5, buckets: 12 };
ex.WEEK = { per: time.HOUR, buckets: 7 * 24 };

ex.min  = function () { return new ex.DataStore(ex.MIN) };
ex.hour = function () { return new ex.DataStore(ex.HOUR) };
ex.day  = function () { return new ex.DataStore(ex.DAY) };
ex.week = function () { return new ex.DataStore(ex.WEEK) };

