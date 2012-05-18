
mongoose = require 'mongoose'
Schema = mongoose.Schema
Friend = require './friend'
Link = require './link'

personSchema = new Schema
  facebookId: String
  isAppUser: Boolean
  name:  String
  updatedDate: Date
  links: [Link.schema]
  linksUpdatedDate: Date
  friends: [{
    facebookId: String
    name:  String
  }]
  friendsUpdatedDate: Date


m = () ->
  @links.forEach (link) ->
    emit(link.url, {
      count: 1
      sharedBy: [{
        id: @facebookId
        friends: @friends
        isAppUser: @isAppUser
      }]
    })

r = (key, values) ->
  sharedBy = []
  count = 0
  values.forEach (value) ->
    sharedBy = sharedBy.concat value.sharedBy
    count += value.count
  return {
    count: count
    sharedBy: sharedBy
  }

f = (key, value) ->
  value.sharedBy.forEach (person) ->
    cnt = 0
    person.friends.forEach (friend) ->
      if (value.sharedBy.some (person1) -> friend.id == person1.id)
        ++cnt
    person.mutualCount = cnt;
    #NaN if 0
    person.mutualPercent = 100 * cnt / person.friends.length

  return value


#friendSchema.post 'save', (next) ->
personSchema.statics.countMutualLinks = (callback) ->
  this.collection.mapReduce(m, r, {
    finalize: f
    out: 'countMutualLinks'
  }, callback)

personSchema.statics.getCountMutualLinks = (callback) ->
  mongoose.connection.db.collection 'countMutualLinks', (err, collection) ->
    return callback(err) if err
    collection.find({}).sort({'value': -1}).limit(10).toArray (err, links) ->
      return callback(err) if err
      callback(null, links)



module.exports = mongoose.model 'Person', personSchema