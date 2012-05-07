mongoose = require 'mongoose'
Schema = mongoose.Schema
FriendInfo = require './friend-info'
Link = require './link'
  
friendSchema = new Schema
    name:  String
    facebookId: String
    ownerFacebookId: String
    updatedDate: Date
    links: [Link.schema]
    mutualFriends: [FriendInfo.schema]


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
friendSchema.statics.countMutualLinks = (callback) ->
  this.collection.mapReduce(m, r, {
    finalize: f
    out: 'countMutualLinks'
  }, callback)

module.exports = mongoose.model 'Friend', friendSchema