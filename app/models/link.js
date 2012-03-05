// The Link model

var mongoose = require('mongoose')
  , Schema = mongoose.Schema
   //,ObjectId = Schema.ObjectId;

var linkSchema = new Schema({
    date: {type: Date, default: Date.now},
    facebookId: String,
    //author: {type: String, default: 'Anon'},
    url: String
});

//linkSchema.method('test', function(i) {
//return 'works' + this.body + " " + i;
//});

module.exports = mongoose.model('Link', linkSchema);