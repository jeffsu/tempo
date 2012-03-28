require('mochiscript');

console.log('Testing data-store');
require('./data-store');

console.log('Testing average');
require('./average');

console.log('Testing sync');
require('./sync');

setTimeout(function () { console.log("Passed!") }, 2000);
