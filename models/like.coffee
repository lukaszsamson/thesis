
mongoose = require 'mongoose'
Schema = mongoose.Schema


LikeSchema = new Schema
  facebookId: String
  name: String
  category: String
  created_time: Date


module.exports = mongoose.model 'Like', LikeSchema