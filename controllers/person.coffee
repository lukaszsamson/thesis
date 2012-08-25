Graph = require('../utils/graph-client').Graph
User = require '../models/user'
Person = require '../models/person'
util = require 'util'
jobs = require('../utils/jobs')


exports.logOutFromFacebook = (req, res) ->
  delete req.session.facebookToken

exports.deleteFacebookData = (req, res, next) ->
  Person.remove({facebookId: facebookId}, (e) ->
    next(e) if e
    res.send 200
  )

exports.countLinks = (req, res, next) ->
  jobs.countLinks (e) ->
    return next(e) if e
    res.send 200

exports.countLikesByName = (req, res, next) ->
  jobs.countLikesByName (e) ->
    return next(e) if e
    res.send 200

exports.countLikesByCategory = (req, res, next) ->
  jobs.countLikesByCategory (e) ->
    return next(e) if e
    res.send 200
    
exports.links = (req, res, next) ->
  Person.getLinks (e, links) ->
    return next(e) if e
    res.render('person/links', {
      title: 'Links'
      id: '/links'
      menu:
        '/person': 'Person'
        '/person/links': 'Links'
        '/person/likes/byName': 'Likes by name'
        '/person/likes/byCategory': 'Likes by category'
      loggedIn: loggedIn: req.loggedIn?
      links: links
    })

exports.likesByName = (req, res, next) ->
  Person.getLikesByName (e, likes) ->
    return next(e) if e
    res.render('person/likes', {
      title: 'Likes by name'
      id: '/likes/byName'
      menu:
        '/person': 'Person'
        '/person/links': 'Links'
        '/person/likes/byName': 'Likes by name'
        '/person/likes/byCategory': 'Likes by category'
      loggedIn: loggedIn: req.loggedIn?
      likes: likes
    })

exports.likesByCategory = (req, res, next) ->
  Person.getLikesByCategory (e, likes) ->
    return next(e) if e
    res.render('person/likes', {
      title: 'Likes by category'
      id: '/likes/byCategory'
      menu:
        '/person': 'Person'
        '/person/links': 'Links'
        '/person/likes/byName': 'Likes by name'
        '/person/likes/byCategory': 'Likes by category'
      loggedIn: loggedIn: req.loggedIn?
      likes: likes
    })
    
exports.index = (req, res) ->
  res.render 'person/index', {
    title: 'Person'
    id: '/person'
    menu:
      '/person': 'Person'
      '/person/links': 'Links'
      '/person/likes/byName': 'Likes by name'
      '/person/likes/byCategory': 'Likes by category'
    loggedIn: loggedIn: req.loggedIn?
  }
exports.getData = (req, res, next) ->  
  jobs.getAppUser(getToken(req), (e) ->
    return next(e) if e
    res.send 200
  )


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



