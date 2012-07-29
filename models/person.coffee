
mongoose = require 'mongoose'
Schema = mongoose.Schema
Friend = require './friend'
Link = require './link'

personSchema = new Schema
  facebookId: String
  name:  String
  updatedDate: Date
  links: [Link.schema]
  linksUpdatedDate: Date
  friends: [Friend.schema]
  friendsUpdatedDate: Date


m = () ->
  @links.forEach (link) ->
    emit(link.url, {
      count: 1
      sharedBy: [{
        id: @facebookId
        friends: @friends.map (f) -> {
          id: f.facebookId
          name: f.name
        }
        isAppUser: true
      }]
    })
  @friends.forEach (friend) ->
    friend.links.forEach (link) ->
      emit(link.url, {
        count: 1
        sharedBy: [{
          id: friend.facebookId
          friends: friend.mutualFriends.concat({
            id: @facebookId
            name: @name
          })
          isAppUser: false
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
links = {}
links.m = () ->
  @links.forEach (link) =>
    emit(link.url, {
      sharedBy: [@facebookId]
      count: 1
    })
  @friends.forEach (friend) ->
    friend.links.forEach (link) ->
      emit(link.url, {
        sharedBy: [friend.facebookId]
        count: 1
      })
    
links.r = (key, values) ->
  sharedBy = []
  count = 0
  values.forEach (value) ->
    sharedBy = sharedBy.concat value.sharedBy
    count += value.count
  return {
    count: count
    sharedBy: sharedBy
  }
 

#friendSchema.post 'save', (next) ->
personSchema.statics.countLinks = (callback) ->
  this.collection.mapReduce(links.m, links.r, {
    #finalize: f
    out: 'links'
  }, callback)

personSchema.statics.getCountMutualLinks = (callback) ->
  mongoose.connection.db.collection 'countMutualLinks', (err, collection) ->
    return callback(err) if err
    collection.find({}).sort({'value': -1}).limit(10).toArray (err, links) ->
      return callback(err) if err
      callback(null, links)

personSchema.statics.getLinks = (callback) ->
  mongoose.connection.db.collection 'links', (err, collection) ->
    return callback(err) if err
    collection.find({}).sort({'value.count': -1}).limit(10).toArray (err, links) ->
      return callback(err) if err
      callback(null, links)

module.exports = mongoose.model 'Person', personSchema