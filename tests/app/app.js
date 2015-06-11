var path = require('path')
var express = require('express')
var app = express()

ExpressPermissions = require(path.join(__dirname, '..', '..'))

app.use(ExpressPermissions.middleware())

ExpressPermissions.add(app, '/', function (req, res){
  return true
})
ExpressPermissions.add(app, '/test/:type', function (req, res){
  return true
})

ExpressPermissions.add(app, '/403', false)

app.get('/', function (req, res) {
  res.send('Hello World!');
});

app.get('/test/:type', function (req, res){
  res.send(req.params.type)
})

app.permissionDenied = function (req, res){
  res.send('access denied')
}

var server = app.listen(3000, function () {

  var host = server.address().address;
  var port = server.address().port;

  console.log('Example app listening at http://%s:%s', host, port);

});
