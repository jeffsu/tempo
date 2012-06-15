require('mochiscript');

console.log('Sparse Logger');
require('./sparse-logger');

console.log('Testing data-store');
require('./data-store');

console.log('Testing average');
require('./average');

console.log('Testing sync');
require('./sync');

console.log('Testing keys and attrs');
require('./keys-and-attrs');


setTimeout(function () { console.log("Passed!"); process.exit(0); }, 2000);
