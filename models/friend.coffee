mongoose = require 'mongoose'
Schema = mongoose.Schema
FriendInfo = require './friend-info'
Link = require './link'
  
friendSchema = new Schema
    name:  String
    facebookId: String
    ownerFacebookId: String
    updatedDate: Date
    links: [Link.schema]
    mutualFriends: [FriendInfo.schema]

module.exports = mongoose.model 'Friend', friendSchema