var express = require('express');


module.exports = function() {
  this.set('views', __dirname + '/../../app/views');
  this.set('view engine', 'ejs');
  this.set('facebook app id', '102219526568766')
  this.set('facebook app secret', 'ee755ea1ef4ab900bb46b497d5a93ca0')


  this.use(express.cookieParser());
  this.use(express.session({ secret: "shoop da woop" }));

  this.use(express.logger());
  this.use(express.bodyParser());
  this.use(this.router);
  this.use(express.static(__dirname + '/../../public'));
  this.datastore(require('locomotive-mongoose'));

}
