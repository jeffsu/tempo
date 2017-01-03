require('mochiscript');

require('nodeunit')
  .reporters
  .default
  .run([
    'tests/functional.ms',
    'tests/increment.ms',
    'tests/iterators.ms',
    'tests/syncer.ms',
    'tests/offsets.ms'
  ]);
