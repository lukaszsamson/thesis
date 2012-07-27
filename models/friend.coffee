mongoose = require 'mongoose'
Schema = mongoose.Schema
Link = require './link'

friendSchema = new Schema
    name:  String,
    facebookId: String
    links: [Link.schema]
    linksUpdatedDate: Date
    #mutualFriendsUpdatedDate: Date
    mutualFriends: [{
    name: String
    facebookId: String
    }]


module.exports = mongoose.model 'Friend', friendSchema