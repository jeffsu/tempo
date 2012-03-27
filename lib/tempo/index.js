require('mochiscript');
module.exports.DataStore   = require('./data-store');
module.exports.Counter     = require('./counter');
module.exports.Average     = require('./average');
module.exports.AttrCounter = require('./attr-counter');
module.exports.now = function () { return (new Date()).getTime() };
