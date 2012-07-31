
mongoose = require 'mongoose'
Schema = mongoose.Schema
Friend = require './friend'
Link = require './link'

PersonSchema = new Schema
  facebookId: String
  updatedDate: Date
  firstName: String
  lastName: String
  gender: String
  name:  String
  links: [Link.schema]
  linksUpdatedDate: Date
  friends: [Friend.schema]
  friendsUpdatedDate: Date

PersonSchema.statics.saveOrUpdate = (personData, done) ->
  this.findOne({
    facebookId: personData.id
  }, (error, person) ->
    return done(error) if error
    if not person
      new Person(
        name: personData.name
        firstName: personData.first_name
        lastName: personData.last_name
        gender: personData.gender
        facebookId: personData.id
        createdDate: new Date
        updatedDate: new Date
      ).save done
    else
      person.name = personData.name
      firstName: personData.first_name
      lastName: personData.last_name
      gender: personData.gender
      person.updatedDate = new Date
      person.save(done)
  )

PersonSchema.statics.updateFriend = (personId, friend, done) ->
  this.update({
      facebookId: personId
      'friends.facebookId': friend.id
    }, {
      $set: {
        'friends.$.gender': friend.gender
        'friends.$.updatedDate': new Date
      }
    }, {
      multi: false
    }, done)
  
  
PersonSchema.statics.updateLinks = (personId, links, done) ->
  this.update({
      facebookId: personId
    }, {
      $set: {
        linksUpdatedDate: new Date
        links: links.map((link) ->
          new Link(
            url: link.link,
            facebookId: link.id
          )
        )
      }
    }, {
      multi: false
    }, done)
    
PersonSchema.statics.updateFriendLinks = (personId, friendId, links, done) ->
  this.update({
      facebookId: personId
      'friends.facebookId': friendId
    }, {
      $set: {
        'friends.$.linksUpdatedDate': new Date
        'friends.$.links': links.map((link) ->
          new Link(
            url: link.link,
            facebookId: link.id
          )
        )
      }
    }, {
      multi: false
    }, done)
  
PersonSchema.statics.updateFrineds = (personId, friends, done) ->
  this.update({
      facebookId: personId,
    }, {
      $set: {
        friendsUpdatedDate: new Date
        friends: friends.map (friend) ->
          new Friend(
            facebookId: friend.id,
            name: friend.name
          )
      }
    }, {
      multi: false
    }, done)
  
PersonSchema.statics.updateMutualFrineds = (personId, friendId, mutualFriends, done) ->
  this.update({
      facebookId: personId,
      'friends.facebookId': friendId,
    }, {
      $set: {
        'friends.$.mutualFriendsUpdatedDate': new Date
        'friends.$.mutualFriends': mutualFriends.map (mutualFriend) ->
          facebookId: mutualFriend.id,
          name: mutualFriend.name
      }
    }, {
      multi: false
    }, done)
  
  
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
PersonSchema.statics.countLinks = (callback) ->
  this.collection.mapReduce(links.m, links.r, {
    #finalize: f
    out: 'links'
  }, callback)

PersonSchema.statics.getCountMutualLinks = (callback) ->
  mongoose.connection.db.collection 'countMutualLinks', (err, collection) ->
    return callback(err) if err
    collection.find({}).sort({'value': -1}).limit(10).toArray (err, links) ->
      return callback(err) if err
      callback(null, links)

PersonSchema.statics.getLinks = (callback) ->
  mongoose.connection.db.collection 'links', (err, collection) ->
    return callback(err) if err
    collection.find({}).sort({'value.count': -1}).limit(10).toArray (err, links) ->
      return callback(err) if err
      callback(null, links)

Person = mongoose.model 'Person', PersonSchema
module.exports = Person