kue = require 'kue'
jobs = kue.createQueue()
Job = kue.Job;
async = require 'async'
Graph = require('../utils/graph-client').Graph
User = require '../models/user'
Person = require '../models/person'

countLinks = (done) ->
  console.log 'Creating countLinks job'
  jobs.create('countLinks', {
    title: 'Counting links'
  }).save done

jobs.process 'countLinks', 3, (job, done) ->
  Person.countLinks(done)

exports.getAppUser = (access_token, done) ->
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
        (c2) -> getFriends(appUser, job.data.access_token, c2)
      ], c1)
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
    (c0) -> (new Graph(job.data.access_token)).getFriend job.data.friend.id, c0
  , (friend, c0) -> async.series [
      (c1) -> Person.updateFriend job.data.appUser, friend, c1
    , (c1) -> async.parallel [
        (c2) -> getLinks friend, job.data.access_token, c2
      , (c2) -> getMutualFriends job.data.appUser, friend, job.data.access_token, c2
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
  .save done

jobs.process 'getMutualFriends', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getMutualFriends job.data.friend.id, c0
  , (mutualFriends, c0) -> updateMutualFrineds job.data.person.id, job.data.friend.id, mutualFriends, c0
  ], done


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


jobs.on 'job complete', (id) ->
  #return
  Job.get id, (err, job) ->
    if err
      console.log 'Error while getting job #%d', job.id
      console.log err
      return
    job.remove (err) ->
      if err
        console.log 'Error while removing job #%d', job.id
        console.log err
        return