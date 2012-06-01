require('mochiscript');

var ex = module.exports;

ex.DataStore   = require('./data-store');
ex.Counter     = require('./counter');
ex.Average     = require('./average');
ex.AttrCounter = require('./attr-counter');
ex.SparseLogger = require('./sparse-logger');
ex.now = function () { return (new Date()).getTime() };

var SEC  = 1000;
var MIN  = SEC * 60;
var HOUR = MIN * 60;
var DAY  = HOUR * 24;

ex.MIN  = { per: SEC * 5, buckets: 12 };
ex.DAY  = { per: HOUR, buckets: 24 };
ex.HOUR = { per: MIN * 5, buckets: 12 };
ex.WEEK = { per: HOUR, buckets: 7 * 24 };

ex.min  = function () { return new ex.DataStore(ex.MIN) };
ex.hour = function () { return new ex.DataStore(ex.HOUR) };
ex.day  = function () { return new ex.DataStore(ex.DAY) };
ex.week = function () { return new ex.DataStore(ex.WEEK) };
