var connect = require('connect');
var tempo   = require('../lib/tempo');

var min  = tempo.min();
var hour = tempo.hour();

var urls = {};
var ids  = {};
var id   = 0;

var app = connect();
app.use(function (req, res, next) {
  var startTime = (new Date).getTime();
  var url       = req.url;

  var end = res.end;
  res.end = function () {
    var time = (new Date).getTime() - startTime;
    min.increment('times', url, time);
    hour.increment('times', url, time);
    end.apply(res, arguments);
  }

  next();
});

app.use(function (req, res, next) { 
  var url = req.url;
  urls[url] = true;
  min.increment('urls', url); 
  hour.increment('urls', url); 
  res.end("Logging:" + url);
})

console.log('listening on port 3333 (go to any url)');
app.listen(3333);

setInterval(function () {
  console.log("TEMPO REPORT (PAST HOUR):");
  for (var url in urls) {
    console.log('  ' + url);
    console.log('    requests:  ' + hour.getTotal('urls', url));
    console.log('    resp time: ' + hour.getTotal('times', url) / hour.getTotal('urls', url));
  }
}, 5000);



