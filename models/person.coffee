
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
  friends: [Friend.schema]
  friendsUpdatedDate: Date


m = () ->
  @links.forEach (link) ->
    emit(link.url, {
      count: 1,
      id: @facebookId
    })
  if @isAppUser
    emit(@facebookId, {
      friends: @friends
    })

r = (key, values) ->
  ids = []
  cnt = 0
  values.forEach (value) ->
    ids = ids.push value.id
    cnt += value.count
  return {
    count: cnt
    ids: ids
  }

f = (key, value) ->
  value.ids.forEach (id) ->
    cnt = 0
    id.mutualFriends.forEach (mutualFriend) ->
      if value.ids.some (id1) -> mutualFriend == id1.id
        ++cnt
    id.mutualCount = cnt;
    #NaN if 0
    id.mutualPercent = 100 * cnt / id.mutualFriends.length

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