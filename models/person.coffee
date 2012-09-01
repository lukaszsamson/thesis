
mongoose = require 'mongoose'
Schema = mongoose.Schema
Friend = require './friend'
Link = require './link'
Like = require './like'
Transforms = require('../models/query')

PersonSchema = new Schema
  facebookId: String
  updatedDate: Date
  firstName: String
  lastName: String
  gender: String
  name:  String
  links: [Link.schema]
  linksUpdatedDate: Date
  likes: [Like.schema]
  likesUpdatedDate: Date
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
            link: link.link
            facebookId: link.id
            name: link.name ? ''
            message: link.message ? ''
            created_time: new Date(Date.parse(link.created_time))
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
            link: link.link
            facebookId: link.id
            name: link.name ? ''
            message: link.message ? ''
            created_time: new Date(Date.parse(link.created_time))
          )
        )
      }
    }, {
      multi: false
    }, done)

PersonSchema.statics.updateLikes = (personId, likes, done) ->
  this.update({
      facebookId: personId
    }, {
      $set: {
        likesUpdatedDate: new Date
        likes: likes.map((like) ->
          new Like(
            facebookId: like.id
            name: like.name ? ''
            category: like.category ? ''
            created_time: new Date(Date.parse(like.created_time))
          )
        )
      }
    }, {
      multi: false
    }, done)
    
PersonSchema.statics.updateFriendLikes = (personId, friendId, likes, done) ->
  this.update({
      facebookId: personId
      'friends.facebookId': friendId
    }, {
      $set: {
        'friends.$.likesUpdatedDate': new Date
        'friends.$.likes': likes.map((like) ->
          new Like(
            facebookId: like.id
            name: like.name ? ''
            category: like.category ? ''
            created_time: new Date(Date.parse(like.created_time))
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
    emit(link.link, {
      sharedBy: [{
          id: @facebookId
          date: link.created_time
        }]
      count: 1
    })
  @friends.forEach (friend) ->
    friend.links.forEach (link) ->
      emit(link.link, {
        sharedBy: [{
          id: friend.facebookId
          date: link.created_time
        }]
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
links.f = (key, value) ->
  value.sharedBy.sort (a, b) ->
    if a.date < b.date
      return -1;
    if a.date < b.date
      return 1;
    return 0

  return value




PersonSchema.statics.mapReduceResults = (operation, facebookId, callback) ->
  mongoose.connection.db.collection operation, (err, collection) ->
    return callback(err) if err
    collection.findOne {_id: facebookId}, (err, result) ->
      return callback(err) if err
      callback(null, result)

PersonSchema.statics.mapReduceRequest = (operation, callback) ->
  transforms = Transforms[operation]
  args = {
    out: operation
  }
  if transforms.f
    args['finalize'] = transforms.f
  @collection.mapReduce(transforms.m, transforms.r, args, callback)

Person = mongoose.model 'Person', PersonSchema
module.exports = Person

#db.links.group({key:'value.count', initial:{c:[]},reduce:function(o,p){if(p.c[o.value.count]){p.c[o.value.count]++;}else{p.c[o.value.count]=1}}})
