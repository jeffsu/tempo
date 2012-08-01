require('mochiscript');

console.log('Sparse Logger');
require('./sparse-logger');

console.log('Testing data-store');
require('./data-store');

console.log('Testing sync');
require('./sync');

setTimeout(function () { console.log("Passed!"); process.exit(0); }, 3000);
