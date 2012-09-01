Graph = require('../utils/graph-client').Graph
User = require '../models/user'
Person = require '../models/person'
util = require 'util'
jobs = require('../utils/jobs')

Transforms = require('../models/query')

exports.deleteFacebookData = (req, res, next) ->
  Person.remove({facebookId: req.session.facebookData.id}, (e) ->
    next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Data deleted.'
    }
  )

exports.validateMapReduceOperation = (req, res, next) ->
  operation = req.params[0].split('/')[0]
  req.operation = operation
  if not Transforms.validate(operation)
    error = new Error("Invalid operation #{operation}")
    error.status = 403
    return next(error)
  next(null)

exports.mapReduceResults = (req, res, next) ->
  Person.mapReduceResults req.operation, req.session.facebookData.id, (e, results) ->
    return next(e) if e
    if not results
      error = new Error("Not found")
      error.status = 404
      return next(error)
    res.send(results.value)

exports.mapReduce = (req, res, next) ->
  jobs.mapReduceRequest req.operation, req.sessionID, (e) ->
    return next(e) if e
    res.send 200, {
      header: 'Info'
      body: "#{req.operation} requested."
    }

exports.countLinksHistogram = (req, res, next) ->
  jobs.countLinksHistogram req.sessionID, (e) ->
    return next(e) if e
    res.send 200, {
    header: 'Info'
    body: 'Count links histogram requested.'
    }

exports.logisticRegressionOnLinks = (req, res, next) ->
  jobs.logisticRegressionOnLinks req.sessionID, (e) ->
    return next(e) if e
    res.send 200, {
    header: 'Info'
    body: 'Logistic regression on links requested.'
    }

exports.countLinks = (req, res, next) ->
  jobs.countLinks req.sessionID, (e) ->
    return next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Count links requested.'
    }


exports.countLikesByName = (req, res, next) ->
  jobs.countLikesByName req.sessionID, (e) ->
    return next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Count likes by name requested.'
    }

exports.countLikesByCategory = (req, res, next) ->
  jobs.countLikesByCategory req.sessionID, (e) ->
    return next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Count likes by category requested.'
    }

exports.getLinksHistogram = (req, res, next) ->
  Person.getLinksHistogram req.session.facebookData.id, (e, hg) ->
    return next(e) if e
    if not hg
      er = new Error("Not found")
      er.status = 404
      return next(er)
    res.send(hg.value)

exports.links = (req, res, next) ->
  Person.getLinks (e, links) ->
    return next(e) if e
    res.render('person/links', {
      title: 'Links'
      id: '/links'
      menu:
        '/person': 'Person'
        '/person/friends': 'Friends'
        '/person/links': 'Links'
        '/person/links/chord': 'Links chord'
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
        '/person/friends': 'Friends'
        '/person/links': 'Links'
        '/person/links/chord': 'Links chord'
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
        '/person/friends': 'Friends'
        '/person/links': 'Links'
        '/person/links/chord': 'Links chord'
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
      '/person/friends': 'Friends'
      '/person/links': 'Links'
      '/person/links/chord': 'Links chord'
      '/person/likes/byName': 'Likes by name'
      '/person/likes/byCategory': 'Likes by category'
    loggedIn: loggedIn: req.loggedIn?
  }

exports.friends = (req, res) ->
  res.render 'person/friends', {
    title: 'Friends'
    id: '/person/friends'
    menu:
      '/person': 'Person'
      '/person/friends': 'Friends'
      '/person/links': 'Links'
      '/person/links/chord': 'Links chord'
      '/person/likes/byName': 'Likes by name'
      '/person/likes/byCategory': 'Likes by category'
    loggedIn: loggedIn: req.loggedIn?
  }

exports.linksChord = (req, res) ->
  res.render 'person/linksChord', {
  title: 'Links chord'
  id: '/person/links/chord'
  menu:
    '/person': 'Person'
    '/person/friends': 'Friends'
    '/person/links': 'Links'
    '/person/links/chord': 'Links chord'
    '/person/likes/byName': 'Likes by name'
    '/person/likes/byCategory': 'Likes by category'
  loggedIn: loggedIn: req.loggedIn?
  }

exports.getData = (req, res, next) ->
  jobs.getAppUser( req.sessionID, req.session.facebookToken.access_token, (e) ->
    return next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Data requested.'
    }
  )







