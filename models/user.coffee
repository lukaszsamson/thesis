
mongoose = require 'mongoose'
Schema = mongoose.Schema
Friend = require './friend'
Link = require './link'

#basic account information
#https://developers.facebook.com/policy/#definitions

UserSchema = new Schema
  facebookId: String
  createdDate: Date
  updatedDate: Date
  facebookToken: {
    token: String
    expires: Date
  }
  #basic info
  name:  String
  email: String
  gender: String
  birthday: Date
  currentCity: String
  profilePictureURL: String


  
#TODO upsert?
#TODO more data
#TODO token
UserSchema.statics.saveOrUpdate = (userData, done) ->
  this.findOne({
    facebookId: userData.id
  }, (error, user) ->
    return done(error) if error
    if not user
      new User(
        name: userData.name
        facebookId: userData.id
        createdDate: new Date
        updatedDate: new Date
      ).save done
    else
      user.name = userData.name
      user.updatedDate = new Date
      user.save done
  )
User = mongoose.model 'User', UserSchema
module.exports = User