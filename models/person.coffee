
mongoose = require 'mongoose'
Schema = mongoose.Schema
FriendInfo = require './friend-info'
Link = require './link'

personSchema = new Schema
  facebookId: String
  isAppUser: Boolean
  name:  String
  updatedDate: Date
  links: [Link.schema]
  linksUpdatedDate: Date
  friends: [FriendInfo.schema]
  friendsUpdatedDate: Date


m = () ->
  @links.forEach (link) ->
    emit(link.url, {
      count: 1,
      ids: [{
        id: @facebookId
      , mutualFriends: @mutualFriends.map (mutualFriend) -> mutualFriend.facebookId
      }]
    })

r = (key, values) ->
  ids = []
  cnt = 0
  values.forEach (value) ->
    ids = ids.concat value.ids
    cnt += i.count
  return {
    count: cnt
    ids: ids
  }

f = (key, value) ->
  value.ids.forEach (id) ->
    cnt = 0
    id.mutualFriends.forEach (mutualFriend) ->
      #TODO for should be faster
      if value.ids.filter((id1) -> mutualFriend == id1.id).length != 0
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