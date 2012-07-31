mongoose = require 'mongoose'
Schema = mongoose.Schema
Link = require './link'
Like = require './like'

friendSchema = new Schema
    facebookId: String
    updatedDate: Date
    name:  String,
    firstName: String
    lastName: String
    gender: String
    links: [Link.schema]
    linksUpdatedDate: Date
    likes: [Like.schema]
    likesUpdatedDate: Date
    mutualFriendsUpdatedDate: Date
    mutualFriends: [{
      name: String
      facebookId: String
    }]


module.exports = mongoose.model 'Friend', friendSchema