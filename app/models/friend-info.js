// The FriendInfo model

var mongoose = require('mongoose')
  , Schema = mongoose.Schema;
  
var friendInfoSchema = new Schema({
    name:  String,
    facebookId: String,
});

module.exports = mongoose.model('FriendInfo', friendInfoSchema);