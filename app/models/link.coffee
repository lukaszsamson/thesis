
mongoose = require 'mongoose'
Schema = mongoose.Schema


linkSchema = new Schema(
    date: (type: Date, default: Date.now),
    facebookId: String,
    url: String
)

exports = mongoose.model 'Link', linkSchema