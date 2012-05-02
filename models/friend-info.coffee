mongoose = require 'mongoose'
Schema = mongoose.Schema
  
friendInfoSchema = new Schema
    name:  String,
    facebookId: String


module.exports = mongoose.model 'FriendInfo', friendInfoSchema