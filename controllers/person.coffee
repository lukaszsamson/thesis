Graph = require('../utils/graph-client').Graph
Person = require '../models/person'
Friend = require '../models/friend'
Link = require '../models/link'
Document = require '../models/document'
util = require 'util'
async = require 'async'
request = require '../utils/safe-request'

kue = require 'kue'

jobs = kue.createQueue()
Job = kue.Job;


exports.test = (req, res) ->
  getMe getToken(req), (e) ->
    return res.error e if e
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


getMe = (access_token, done) ->
  console.log 'Creating getMe job'
  jobs.create 'get me',
    title: 'Getting me'
    access_token: access_token
  .attempts(3)
  .save done


getFriend = (me, friend, access_token, done) ->
  console.log 'Creating getFriend job'
  jobs.create 'get friend',
    title: 'Getting friend ' + friend.name
    me: me
    friend: friend
    access_token: access_token
  .attempts(3)
  .save done


getFriends = (me, access_token, done) ->
  console.log 'Creating getFriends job'
  jobs.create 'get friends',
    title: 'Getting friends'
    me: me
    access_token: access_token
  .attempts(3)
  .save done


getMutualFriends = (friend, access_token, done) ->
  console.log 'Creating getMutualFriends job for %s', friend.name
  jobs.create('get mutual friends',
    title: 'Getting mutual friends of ' + friend.name
    friend: friend
    access_token: access_token
  ).attempts(3)
  .save done


getMyLinks = (me, access_token, done) ->
  console.log 'Creating getLinks job for %s', me.name
  jobs.create('get my links',
    title: 'Getting links submitted by ' + me.name
    me: me
    access_token: access_token
  ).attempts(3)
  .save done


getLinks = (friend, access_token, done) ->
  console.log 'Creating getLinks job for %s', friend.name
  jobs.create('get links',
    title: 'Getting links submitted by ' + friend.name
    friend: friend
    access_token: access_token
  ).attempts(3)
  .save done

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

jobs.process 'get me', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getMe c0
  , (me, c0) -> async.series [
      (c1) -> saveOrUpdatePerson me, c1
    , (c1) -> async.parallel [
        (c2) -> getMyLinks me, job.data.access_token, c2
      , (c2) -> getFriends me, job.data.access_token, c2
      ], c1
    ], c0
  ], done


jobs.process 'get friend', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getFriend job.data.friend.id, c0
  , (friend, c0) -> async.series [
      (c1) -> saveOrUpdateFriend job.data.me, friend, c1
    , (c1) -> async.parallel [
        (c2) -> getLinks friend, job.data.access_token, c2
      , (c2) -> getMutualFriends friend, job.data.access_token, c2
      ], c1
    ], c0
  ], done


jobs.process 'get friends', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getFriends c0
  , (friends, c0) -> async.series [
      (c1) -> updateFrineds job.data.me.id, friends, c1
    , (c1) -> async.forEach friends, ((friend, c2) -> getFriend job.data.me, friend, job.data.access_token, c2), c1
    ], c0
  ], done

jobs.process 'get mutual friends', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getMutualFriends job.data.friend.id, c0
  , (mutualFriends, c0) -> updateMutualFrineds job.data.friend.id, mutualFriends, c0
  ], done


jobs.process 'get my links', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getLinks job.data.me.id, c0
  , (links, c0) -> updatePersonLinks job.data.me.id, links, c0
  ], done


jobs.process 'get links', 3, (job, done) ->
  async.waterfall [
    (c0) -> (new Graph(job.data.access_token)).getLinks job.data.friend.id, c0
  , (links, c0) -> async.series [
      (c1) -> updateFriendLinks job.data.friend.id, links, c1
    #, (c1) -> async.forEach links, ((link, c2) -> scrapLink link.link, c2), c1
    ], c0
  ], done


jobs.on 'job complete', (id) ->
  return
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
  Friend.findOne {
    facebookId: friend.id
  }, (error, result) ->
    return done(error) if error
    if not result
      new Friend
        name: friend.name
        facebookId: friend.id
        ownerFacebookId: me.id
        updatedDate: new Date
        links: []
        mutualFriends: []
      .save done
    else
      result.name = friend.name
      result.updatedDate = new Date
      result.links = []
      result.mutualFriends = []
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
        updatedDate: new Date
        links: []
        friends: []
      .save done
    else
      result.name = person.name
      result.updatedDate = new Date
      result.links = []
      result.friends = []
      result.save done


updatePersonLinks = (id, links, done) ->
  Person.update {
      facebookId: id
    }, {
      $pushAll: {
        links: links.map (link) ->
          new Link
            url: link.link,
            facebookId: link.id
      }
    }, {
      multi: false
    }, done


updateFriendLinks = (id, links, done) ->
  Friend.update {
      facebookId: id
    }, {
      $pushAll: {
        links: links.map (link) ->
          new Link
            url: link.link,
            facebookId: link.id
      }
    }, {
      multi: false
    }, done

updateFrineds = (id, friends, done) ->
  Person.update {
      facebookId: id,
    }, {
      $set: {
      friends: friends.map (friend) ->
        facebookId: friend.id,
        name: friend.name
      }
    }, {
      multi: false
    }, done


updateMutualFrineds = (id, mutualFriends, done) ->
  Friend.update {
      facebookId: id,
    }, {
      $set: {
      mutualFriends: mutualFriends.map (mutualFriend) ->
        facebookId: mutualFriend.id,
        name: mutualFriend.name
      }
    }, {
      multi: false
    }, done

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