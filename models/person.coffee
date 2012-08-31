
mongoose = require 'mongoose'
Schema = mongoose.Schema
Friend = require './friend'
Link = require './link'
Like = require './like'

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
  
  
  
friends = {}
friends.m = () ->
  emit(@facebookId, {
    user: true
    friends: @friends.map (friend) -> friend.facebookId
  })
  @friends.forEach((friend) =>
    emit(friend.facebookId, {
      user: false
      friends: friend.mutualFriends.map((mf) -> mf.facebookId).concat(@facebookId)
    })
  )
    
friends.r = (key, values) ->
  fr = []
  count = 0
  values.forEach (value) ->
    value.friends.forEach (friend) ->
      fr.push friend if fr.indexOf friend < 0
  return {
    friends: fr
  }
  
  
  
  
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

 
likes = {}
likes.mbn = () ->
  @likes.forEach((like) =>
    emit(like.name, {
      sharedBy: [@facebookId]
      count: 1
    })
  )
  @friends.forEach((friend) ->
    friend.likes.forEach((like) ->
      emit(like.name, {
        sharedBy: [friend.facebookId]
        count: 1
      })
    )
  )

likes.mbc = () ->
  @likes.forEach((like) =>
    emit(like.category, {
      sharedBy: [@facebookId]
      count: 1
    })
  )
  @friends.forEach((friend) ->
    friend.likes.forEach((like) ->
      emit(like.category, {
        sharedBy: [friend.facebookId]
        count: 1
      })
    )
  )

    
likes.r = (key, values) ->
  sharedBy = []
  count = 0
  values.forEach (value) ->
    sharedBy = sharedBy.concat value.sharedBy
    count += value.count
  return {
    count: count
    sharedBy: sharedBy
  }
 
PersonSchema.statics.countLikesByName = (callback) ->
  this.collection.mapReduce(likes.mbn, likes.r, {
    #finalize: f
    out: 'likesByName'
  }, callback)

PersonSchema.statics.countLikesByCategory = (callback) ->
  this.collection.mapReduce(likes.mbc, likes.r, {
    #finalize: f
    out: 'likesByCategory'
  }, callback)  

PersonSchema.statics.getLikesByName = (callback) ->
  mongoose.connection.db.collection 'likesByName', (err, collection) ->
    return callback(err) if err
    collection.find({}).sort({'value.count': -1}).limit(10).toArray (err, likes) ->
      return callback(err) if err
      callback(null, likes)


PersonSchema.statics.getLikesByCategory = (callback) ->
  mongoose.connection.db.collection 'likesByCategory', (err, collection) ->
    return callback(err) if err
    collection.find({}).sort({'value.count': -1}).limit(10).toArray (err, likes) ->
      return callback(err) if err
      callback(null, likes)      
  
#friendSchema.post 'save', (next) ->
PersonSchema.statics.countLinks = (callback) ->
  this.collection.mapReduce(links.m, links.r, {
    finalize: links.f
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




PersonSchema.statics.logisticRegressionOnLinks = (callback) ->
  this.collection.mapReduce(logisticRegressionOnLinks.m, logisticRegressionOnLinks.r, {
    finalize: logisticRegressionOnLinks.f
    out: 'logisticRegressionOnLinks'
  }, callback)

logisticRegressionOnLinks = {
  m: () ->
    result = {}
    result[@facebookId] = {
      links: @links.map (l) -> l.link
      friends: @friends.map (f) ->  f.facebookId
      user: true
    }
    cnt = 0
    for f in @friends
      if f.mutualFriends.length < 8
        continue
      #if ++cnt > 10
      #  break
      result[f.facebookId] = {
        links: f.links.map (l) -> l.link
        friends: f.mutualFriends.map((mf) -> mf.facebookId).concat(@facebookId)
        user: false
      }
    emit(1, result)

  r: (key, values) ->
    result = {}
    values.forEach (v) ->
      for key, val of v
        if result[key]
          if not result[key].user and val.user
            result[key] = val
        else
          result[key] = val

    return result

  f: (key, ffff) ->
    getLinks = (friends) ->
      links = {}
      for k, v of friends
        v.links.forEach (l) ->
          if links[l]
            links[l]++
          else
            links[l] = 1
      res = []
      for l, t of links
        res.push(l) if t > 1
      return res

    getFriends = (friends, links) ->
      res = {}
      for k, v of friends
        #if links.some((lc) -> v.links.indexOf(lc) != -1)
          res[k] = {
            links: v.links.filter (l) -> links.indexOf(l) != -1
          }
      for k, v of res
        v.friends = friends[k].friends.filter (f) -> res[f]

      return res

    links = getLinks(ffff)
    value = getFriends(ffff, links)


    getScore = (i, j) ->
      score = 0
      for k in [0...links.length]
        if value[i].links.indexOf(links[k]) != -1
          score += w[k]
        if value[j].links.indexOf(links[k]) != -1
          score += w[k]

      return score

    updateWeights = (i, j, update) ->
      for k in [0...links.length]
        if value[i].links.indexOf(links[k]) != -1
          w[k] += update
        if value[j].links.indexOf(links[k]) != -1
          w[k] += update


    w = new Array(links.length)
    for i in [0...w.length]
      w[i] = 0
    delta = 0.002
    res = []
    for q in [0...1000]
      c1 = -1
      for i, t of value
        c2 = -1
        c1++
        for j, y of value
          c2++
          if c2 > c1
            p = 1 / (1 + Math.exp(-getScore(i, j)))
            friends = t.friends.indexOf(j) != -1
            update = (friends - p) * delta
            updateWeights(i, j, update)

      error = 0
      tried = 0
      fp = 0
      fn = 0
      res[q] = {}
      for i, t of value
        for j, y of value
          if i != j
            tried++
            friends = t.friends.indexOf(j) != -1
            score = getScore(i, j) >= 0.5
            #res[q]["#{i} #{j}"] = {
            #score: score
            #friends: friends
            #}
            if friends != score
              error++
              if friends and not score
                fn++
              if not friends and score
                fp++
      res[q].error = error
      print "#{q}: e #{error} fp #{fp} fn #{fn} a #{tried}"

    return {
    coeffs: w
    err: res
    }

  f1: (key, value) ->
    getLinks = (value) ->
      len = 20
      links = []
      for k, v of value
        v.links.forEach (l) ->
          if links.indexOf(l) == -1
            links.push(l)
      result = new Array(len)
      for i in [0..links.length - 1]
        h = i % len
        if not result[h]
          result[h] = []
        result[h].push links[i]
      return result

    getScore = (i, j) ->
      score = 0
      for k in [0..links.length - 1]
        if links[k].some((lc) -> value[i].links.indexOf(lc) != -1)
          score += w[k]
        if links[k].some((lc) -> value[j].links.indexOf(lc) != -1)
          score += w[links.length + k]

      return score

    updateWeights = (i, j, update) ->
      for k in [0..links.length - 1]
        if links[k].some((lc) -> value[i].links.indexOf(lc) != -1)
          w[k] += update
        if links[k].some((lc) -> value[j].links.indexOf(lc) != -1)
          w[links.length + k] += update

    links = getLinks(value)

    w = new Array(links.length * 2)
    for i in [0..w.length - 1]
      w[i] = 0
    delta = 0.002
    res = []
    for q in [0..20]
      for i, t of value
        for j, y of value
          if i != j
            p = 1 / (1 + Math.exp(-getScore(i, j)))
            friends = t.friends.indexOf(j) != -1
            update = (friends - p) * delta
            updateWeights(i, j, update)

      error = 0
      res[q] = {}
      for i, t of value
        for j, y of value
          if i != j
            friends = t.friends.indexOf(j) != -1
            score = getScore(i, j) >= 0
            res[q]["#{i} #{j}"] = {
              score: score
              friends: friends
            }
            if friends != score
              error++
      res[q].error = error

    return {
      coeffs: w
      err: res
    }
}










linksHistogram = {}
linksHistogram.m = () ->
  @links.forEach (l) =>
    r = {}
    r[l.link] = [@facebookId]
    emit(@facebookId, r)
  @friends.forEach (f) =>
    f.links.forEach (l) =>
      r = {}
      r[l.link] = [f.facebookId]
      emit(@facebookId, r)

linksHistogram.r = (key, values) ->
  result = {}
  values.forEach (v) ->
    for l, ids of v
      if result[l]
        result[l] = result[l].concat ids
      else
        result[l] = ids
  return result

linksHistogram.f = (key, value) ->
  result = []
  for l, ids of value
    result.push {
      link: l
      shares: ids.length
    }
  result.sort (a, b) ->
    if a.shares > b.shares
      return 1
    if b.shares > a.shares
      return -1
    return 0
  return result


PersonSchema.statics.getLinksHistogram = (facebookId, callback) ->
  mongoose.connection.db.collection 'linksHistogram', (err, collection) ->
    return callback(err) if err
    collection.findOne {_id: facebookId}, (err, hg) ->
      return callback(err) if err
      callback(null, hg)

PersonSchema.statics.countLinksHistogram = (callback) ->
  @collection.mapReduce(linksHistogram.m, linksHistogram.r, {
    finalize: linksHistogram.f
    out: 'linksHistogram'
  }, callback)



Person = mongoose.model 'Person', PersonSchema
module.exports = Person

#db.links.group({key:'value.count', initial:{c:[]},reduce:function(o,p){if(p.c[o.value.count]){p.c[o.value.count]++;}else{p.c[o.value.count]=1}}})
