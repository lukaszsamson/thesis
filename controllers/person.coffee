Graph = require('../utils/graph-client').Graph
User = require '../models/user'
Person = require '../models/person'
util = require 'util'
jobs = require('../utils/jobs')



menu = require './menu'

exports.deleteFacebookData = (req, res, next) ->
  Person.remove({facebookId: req.session.facebookData.id}, (e) ->
    next(e) if e
    res.send 200, {
      header: 'Info'
      body: 'Data deleted.'
    }
  )









    
exports.index = (req, res) ->
  res.render 'person/index', {
    title: 'Person'
    id: '/person'
    menu: menu
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







