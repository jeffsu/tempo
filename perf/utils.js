
var MB = 1024 * 1024;
module.exports.run = function (name, cb) {
  var finished = false;
  function beat() {
    if (finished) return clearInterval(id);
    var start = (new Date).getTime();
    cb();
    var end = (new Date).getTime();
    var time = end - start;
    console.log(name, time + 'ms');
    console.log(Math.round(process.memoryUsage().rss / MB) + 'mb');
  }

  var id = setInterval(beat, 100);
  setTimeout(function () { finished = true }, 10000);
};




