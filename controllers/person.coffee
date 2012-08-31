Graph = require('../utils/graph-client').Graph
User = require '../models/user'
Person = require '../models/person'
util = require 'util'
jobs = require('../utils/jobs')



exports.deleteFacebookData = (req, res, next) ->
  Person.remove({facebookId: req.session.facebookData.id}, (e) ->
    next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Data deleted.'
    }
  )

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
  jobs.getAppUser( req.sessionID, req.session.facebookToken.access_token, (e) ->
    return next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Data requested.'
    }
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





