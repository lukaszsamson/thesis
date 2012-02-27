// The Person model

var mongoose = require('mongoose')
  , Schema = mongoose.Schema;

var Link = require('./link.js');
  
var personSchema = new Schema({
    name:  String,
    facebookId: String,
    queriedDate: Date,
    links: [Link.schema],
    friends: [String]
});

module.exports = mongoose.model('Person', personSchema);