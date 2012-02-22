// The Thread model

var mongoose = require('mongoose')
  , Schema = mongoose.Schema;

var Post = require('./post.js');
  
var threadSchema = new Schema({
    title:  String,
    postdate: {type: Date, default: Date.now},
    author: {type: String, default: 'Anon'},
    posts: [Post.schema]
});

module.exports = mongoose.model('Thread', threadSchema);