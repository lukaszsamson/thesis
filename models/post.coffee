mongoose = require 'mongoose'
Schema = mongoose.Schema

postSchema = new Schema
  date:
    type: Date
    default: Date.now
  author:
    type: String
    default: 'Anon'
  body: String


postSchema.method 'test', i ->
  'works' + this.body + " " + i

exports = mongoose.model 'Post', postSchema