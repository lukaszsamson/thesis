// The Person model

var mongoose = require('mongoose')
  , Schema = mongoose.Schema;

var Link = require('./link.js');
  
var personSchema = new Schema({
    name:  String,
    facebookId: String,
    links: [Link.schema]
});

module.exports = mongoose.model('Person', personSchema);