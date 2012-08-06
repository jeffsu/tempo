require('mochiscript');

console.log('Sparse Logger');
require('./sparse-logger');

console.log('Testing timed-counter');
require('./timed-counter');

console.log('Testing sync');
require('./sync');

console.log('Testing counter');
require('./counter');

setTimeout(function () { console.log("Passed!"); process.exit(); }, 3000);
