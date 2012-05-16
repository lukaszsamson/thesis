Graph = require('../utils/graph-client').Graph
Person = require '../models/person'
Link = require '../models/link'
Document = require '../models/document'
util = require 'util'
async = require 'async'
request = require '../utils/safe-request'

kue = require 'kue'

jobs = kue.createQueue()
Job = kue.Job;

exports.countLinks = (req, res, next) ->
  countLinks (e) ->
    return next(e) if e
    res.send 200

exports.getCountLinks = (req, res, next) ->
  Person.getCountMutualLinks (e, links) ->
    return next(e) if e
    res.json(JSON.stringify(links))


exports.index = (req, res) ->
  getAppUser getToken(req), (e) ->
    return next(e) if e
    res.render
      token: getToken req
###
function NotFound(msg) {
  Error.call(this);
  Error.captureStackTrace(this, arguments.callee);
  this.name = 'NotFound';
  this.message = msg;
}

NotFound.prototype.__proto__ = Error.prototype;
###


exports.friend = (req, res) ->
  facebookId = req.params.id
  Person.findOne
    facebookId: facebookId
  , (error, result) ->
    return res.error error if error
    return self.error new NotFound util.format 'Friend with id %s does not exist', facebookId if not result
    res.render
      facebookId: facebookId
      links: result.links

exports.friends = (req, res) ->
  Person.find (error, result) ->
    return res.error error if error
    res.render
      friends: result


getToken = (req) ->
  return req.session.facebookToken.access_token if req.session.facebookToken



countLinks = (done) ->
  console.log 'Creating countLinks job'
  jobs.create('gcountLinksd', {
    title: 'Counting links'
  }).save done

jobs.process 'countLinks', 3, (job, done) ->
  Person.countMutualLinks(done)









scrapLink = (url, done) ->
  console.log 'Creating scrapLink job for %s', url
  jobs.create('scrap link',
    title: 'Scrapping link ' + url
    url: url
  ).attempts(3)
  .save done

jobs.process 'scrap link', 3, (job, done) ->
  url = job.data.url
  async.waterfall [
    (c0) -> request url, c0
  , (document, c0) -> saveOrUpdateDocument {
      content: document
      url: url
    }, c0 if document else c0()
  ], done

getAppUser = (access_token, done) ->
  console.log 'Creating getAppUser job'
  jobs.create 'getAppUser',
    title: 'Getting app user'
    access_token: access_token
  .attempts(3)
  .save done

jobs.process 'getAppUser', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getAppUser c0
  , (appUser, c0) -> async.series [
      (c1) -> saveOrUpdatePerson appUser, c1
    , (c1) -> async.parallel [
        (c2) -> getLinks appUser, job.data.access_token, c2
      , (c2) -> getFriends appUser, job.data.access_token, c2
      ], c1
    ], c0
  ], done

getFriend = (appUser, friend, access_token, done) ->
  console.log 'Creating getFriend job'
  jobs.create 'getFriend',
    title: 'Getting friend ' + friend.name
    appUser: appUser
    friend: friend
    access_token: access_token
  .attempts(3)
  .save done


jobs.process 'getFriend', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getFriend job.data.friend.id, c0
  , (friend, c0) -> async.series [
      (c1) -> saveOrUpdateFriend job.data.appUser, friend, c1
    , (c1) -> async.parallel [
        (c2) -> getLinks friend, job.data.access_token, c2
      , (c2) -> getMutualFriends job.data.appUser, friend, job.data.access_token, c2
      ], c1
    ], c0
  ], done


getFriends = (appUser, access_token, done) ->
  console.log 'Creating getFriends job'
  jobs.create 'getFriends',
    title: 'Getting friends'
    appUser: appUser
    access_token: access_token
  .attempts(3)
  .save done

jobs.process 'getFriends', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getFriends c0
  , (friends, c0) -> async.series [
      (c1) -> updateFrineds job.data.appUser.id, friends, c1
    , (c1) -> async.forEach friends, ((friend, c2) ->
        getFriend job.data.appUser, friend, job.data.access_token, c2
      ), c1
    ], c0
  ], done

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

jobs.process 'getLinks', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getLinks job.data.person.id, c0
  , (links, c0) -> async.series [
      (c1) -> updatePersonLinks job.data.person.id, links, c1
    #, (c1) -> async.forEach links, ((link, c2) -> scrapLink link.link, c2), c1
    ], c0
  ], done


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


saveOrUpdateFriend = (me, friend, done) ->
  Person.findOne {
    facebookId: friend.id
  }, (error, result) ->
    return done(error) if error
    if not result
      new Person
        name: friend.name
        facebookId: friend.id
        isAppUser: false
        updatedDate: new Date
      .save done
    else
      result.name = friend.name
      result.updatedDate = new Date
      result.save done


saveOrUpdatePerson = (person, done) ->
  Person.findOne {
    facebookId: person.id
  }, (error, result) ->
    return done(error) if error
    if not result
      new Person
        name: person.name
        facebookId: person.id
        isAppUser: true
        updatedDate: new Date
      .save done
    else
      result.name = person.name
      result.updatedDate = new Date
      result.isAppUser = true
      result.save done


updatePersonLinks = (id, links, done) ->
  Person.update {
      facebookId: id
    }, {
      $set: {
        lunksUpdatedDate: new Date
        links: links.map (link) ->
          new Link
            url: link.link,
            facebookId: link.id
      }
    }, {
      multi: false
    }, done


updateFrineds = (personId, friends, done) ->
  Person.update {
      facebookId: personId,
    }, {
      $set: {
        friendsUpdatedDate: new Date
        friends: friends.map (friend) ->
          facebookId: friend.id,
          name: friend.name
      }
    }, {
      multi: false
    }, done


updateMutualFrineds = (personId, friendId, mutualFriends, done) ->
  Person.update {
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
    }, done
###
saveOrUpdateDocument = (document, done) ->
  Document.findOne {
  url: document.url
  }, (error, result) ->
    return done(error) if error
    if not result
      new Document
        url: document.url
        content: document.content
        updatedDate: new Date
      .save done
    else
      result.content = document.content
      result.updatedDate = new Date
      result.save done
###