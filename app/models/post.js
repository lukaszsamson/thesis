// The Post model

var mongoose = require('mongoose')
   ,Schema = mongoose.Schema
   //,ObjectId = Schema.ObjectId;

var postSchema = new Schema({
    date: {type: Date, default: Date.now},
    author: {type: String, default: 'Anon'},
    body: String
});

postSchema.method('test', function(i) {
return 'works' + this.body + " " + i;
});

module.exports = mongoose.model('Post', postSchema);