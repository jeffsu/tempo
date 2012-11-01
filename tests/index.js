require('mochiscript');
var reporter = require('nodeunit').reporters.default;
reporter.run([ 'tests/functional.ms', 'tests/increment.ms', 'tests/iterators.ms', 'tests/syncer.ms', 'tests/offsets.ms' ]);
