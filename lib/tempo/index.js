require('mochiscript');
module.exports.DataStore = require('./data-store');
module.exports.now = function () { return (new Date()).getTime() };
