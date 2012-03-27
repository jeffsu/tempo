require('mochiscript');

console.log('Testing data-store');
require('./data-store');
console.log('Testing average');
require('./average');

setTimeout(function () { console.log("Passed!") }, 2000);
