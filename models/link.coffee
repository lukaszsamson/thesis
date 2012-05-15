
mongoose = require 'mongoose'
Schema = mongoose.Schema


linkSchema = new Schema
  facebookId: String
  url: String


module.exports = mongoose.model 'Link', linkSchema