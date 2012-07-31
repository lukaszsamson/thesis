
mongoose = require 'mongoose'
Schema = mongoose.Schema


LinkSchema = new Schema
  facebookId: String
  link: String
  name: String
  message: String


module.exports = mongoose.model 'Link', LinkSchema