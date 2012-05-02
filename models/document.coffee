mongoose = require 'mongoose'
Schema = mongoose.Schema


documentSchema = new Schema
  updatedDate:
    type: Date
    default: Date.now
  content: String
  url: String


module.exports = mongoose.model 'Document', documentSchema