var express = require('express');
var mongoose = require('mongoose');
mongoose.connect('mongodb://localhost/test');

module.exports = function() {
  this.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
}
