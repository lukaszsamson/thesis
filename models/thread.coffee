mongoose = require 'mongoose'
Schema = mongoose.Schema;

#Post = require './post'
  
threadSchema = new Schema
  title:  String
  body: String
  author:
    type: String
    default: 'Anon'
  ###
  postdate:
    type: Date
    default: Date.now
  author:
    type: String
    default: 'Anon'
  posts: [Post.schema]
###

module.exports = mongoose.model 'Thread', threadSchema