mongoose = require 'mongoose'
Schema = mongoose.Schema
  
friendInfoSchema = new Schema
    name:  String,
    facebookId: String
    mutualFriendsUpdatedDate: Date
    mutualFriends: [friendInfoSchema]


module.exports = mongoose.model 'FriendInfo', friendInfoSchema