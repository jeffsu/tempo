require('mochiscript');
module.exports.DataStore   = require('./data-store');
module.exports.Counter     = require('./counter');
module.exports.Average     = require('./average');
module.exports.AttrCounter = require('./attr-counter');
module.exports.SparseLogger = require('./sparse-logger');
module.exports.now = function () { return (new Date()).getTime() };

var SEC  = 1000;
var MIN  = SEC * 60;
var HOUR = MIN * 60;
var DAY  = HOUR * 24;

module.exports.MIN  = { per: SEC * 5, buckets: 12 };
module.exports.DAY  = { per: HOUR, buckets: 24 };
module.exports.HOUR = { per: MIN * 5, buckets: 12 };
module.exports.WEEK = { per: HOUR, buckets: 7 * 24 };
