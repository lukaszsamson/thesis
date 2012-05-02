
mongoose = require 'mongoose'
Schema = mongoose.Schema


linkSchema = new Schema
  updatedDate:
      type: Date
      default: Date.now
  facebookId: String
  url: String


module.exports = mongoose.model 'Link', linkSchema