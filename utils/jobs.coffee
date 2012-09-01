kue = require 'kue'
jobs = kue.createQueue()
Job = kue.Job;
async = require 'async'
Graph = require('../utils/graph-client').Graph
User = require '../models/user'
Person = require '../models/person'
sio = require('./socket-communicator')


exports.mapReduceRequest = (operation, sessionID, done) ->
  console.log "Creating map reduce job #{operation} created"
  jobs.create('mapReduceRequest', {
    title: "Map reduce #{operation}"
    operation: operation
    sessionID: sessionID
  }).save done

jobs.process 'mapReduceRequest', 1, (job, done) ->
  Person.mapReduceRequest job.data.operation, (error) ->
    return done(error) if error
    sio.sendVolatile(job.data.sessionID, 'jobCompleted', {
      header: "Success"
      body: "#{job.data.operation} job has heen completed"
    }, done)

  
exports.getAppUser = (sessionID, access_token, done) ->
  console.log 'Creating getAppUser job'
  jobs.create('getAppUser',
    title: 'Getting app user'
    access_token: access_token
  ).attempts(3)
  .save(done)

jobs.process('getAppUser', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getAppUser(c0),
    (appUser, c0) -> async.series([
      (c1) -> User.saveOrUpdate(appUser, c1),
      (c1) -> Person.saveOrUpdate(appUser, c1),
      (c1) -> async.parallel([
        (c2) -> getLinks(appUser, job.data.access_token, c2),
        (c2) -> getLikes(appUser, job.data.access_token, c2),
        (c2) -> getFriends(appUser, job.data.access_token, c2)
      ], c1),
      (c1) ->
        sio.sendVolatile(job.data.sessionID, 'jobCompleted', {
          header: "Success"
          body: "Data recieved. Note that some operations are still pending."
        }, c1)
    ], c0)
  ], done))

getFriend = (appUser, friend, access_token, done) ->
  console.log 'Creating getFriend job'
  jobs.create('getFriend',
    title: 'Getting friend ' + friend.name
    appUser: appUser
    friend: friend
    access_token: access_token
  ).attempts(3)
  .save(done)


jobs.process('getFriend', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getFriend(job.data.friend.id, c0)
  , (friend, c0) -> async.series [
      (c1) -> Person.updateFriend(job.data.appUser.id, friend, c1)
    , (c1) -> async.parallel [
        (c2) -> getFriendLinks(job.data.appUser, friend, job.data.access_token, c2),
        (c2) -> getFriendLikes(job.data.appUser, friend, job.data.access_token, c2),
        (c2) -> getMutualFriends(job.data.appUser, friend, job.data.access_token, c2)
      ], c1
    ], c0
  ], done))


getFriends = (appUser, access_token, done) ->
  console.log 'Creating getFriends job'
  jobs.create('getFriends',
    title: 'Getting friends'
    appUser: appUser
    access_token: access_token
  ).attempts(3)
  .save(done)

jobs.process('getFriends', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getFriends(c0),
    (friends, c0) -> async.series([
      (c1) -> Person.updateFrineds(job.data.appUser.id, friends, c1),
      (c1) -> async.forEach(friends, ((friend, c2) ->
        getFriend(job.data.appUser, friend, job.data.access_token, c2)
      ), c1)
    ], c0)
  ], done))

getMutualFriends = (person, friend, access_token, done) ->
  console.log 'Creating getMutualFriends job for %s', friend.name
  jobs.create('getMutualFriends',
    title: 'Getting mutual friends of ' + friend.name
    person: person
    friend: friend
    access_token: access_token
  ).attempts(3)
  .save(done)

jobs.process('getMutualFriends', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getMutualFriends(job.data.friend.id, c0)
  , (mutualFriends, c0) -> Person.updateMutualFrineds(job.data.person.id, job.data.friend.id, mutualFriends, c0)
  ], done))


getLinks = (person, access_token, done) ->
  console.log 'Creating getLinks job for %s', person.name
  jobs.create('getLinks',
    title: 'Getting links submitted by ' + person.name
    person: person
    access_token: access_token
  ).attempts(3)
  .save done

jobs.process('getLinks', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getLinks(job.data.person.id, c0),
    (links, c0) -> async.series([
      (c1) -> Person.updateLinks(job.data.person.id, links, c1)
    #, (c1) -> async.forEach links, ((link, c2) -> scrapLink link.link, c2), c1
    ], c0)
  ], done))

getFriendLinks = (person, friend, access_token, done) ->
  console.log 'Creating getLinks job for %s', friend.name
  jobs.create('getFriendLinks',
    title: 'Getting links submitted by ' + friend.name
    person: person
    friend: friend
    access_token: access_token
  ).attempts(3)
  .save done

jobs.process('getFriendLinks', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getLinks(job.data.friend.id, c0),
    (links, c0) -> async.series([
      (c1) -> Person.updateFriendLinks(job.data.person.id, job.data.friend.id, links, c1)
    #, (c1) -> async.forEach links, ((link, c2) -> scrapLink link.link, c2), c1
    ], c0)
  ], done))
  
  


getLikes = (person, access_token, done) ->
  console.log 'Creating getLikes job for %s', person.name
  jobs.create('getLikes',
    title: 'Getting likes submitted by ' + person.name
    person: person
    access_token: access_token
  ).attempts(3)
  .save done

jobs.process('getLikes', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getLikes(job.data.person.id, c0),
    (likes, c0) -> Person.updateLikes(job.data.person.id, likes, c0)
  ], done))

getFriendLikes = (person, friend, access_token, done) ->
  console.log 'Creating getLikes job for %s', friend.name
  jobs.create('getFriendLikes',
    title: 'Getting likes submitted by ' + friend.name
    person: person
    friend: friend
    access_token: access_token
  ).attempts(3)
  .save done

jobs.process('getFriendLikes', 3, (job, done) ->
  async.waterfall([
    (c0) -> (new Graph(job.data.access_token)).getLikes(job.data.friend.id, c0),
    (likes, c0) -> Person.updateFriendLikes(job.data.person.id, job.data.friend.id, likes, c0)
  ], done))  
  
jobs.on('job complete', (id) ->
  #return
  Job.get(id, (err, job) ->
    if err
      console.log 'Error while getting job #%d', job.id
      console.log err
      return
    job.remove((err) ->
      if err
        console.log 'Error while removing job #%d', job.id
        console.log err
        return
      )
    )
  )