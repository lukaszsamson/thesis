
mongoose = require 'mongoose'
Schema = mongoose.Schema
FriendInfo = require './friend-info'
Link = require './link.js'

personSchema = new Schema(
  name:  String,
  facebookId: String,
  updatedDate: Date,
  links: [Link.schema],
  friends: [FriendInfo.schema]
)

exports = mongoose.model 'Person', personSchema