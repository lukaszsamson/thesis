menu = require './menu'

exports.index = (req, res, next) ->
  res.render('person/links/index', {
    title: 'Links'
    id: '/person/links'
    menu: menu
    loggedIn: loggedIn: req.loggedIn?
  })

exports.flow = (req, res) ->
  res.render 'person/links/flow', {
    title: 'Links flow'
    id: '/person/links'
    menu: menu
    loggedIn: loggedIn: req.loggedIn?
  }

exports.histogram = (req, res) ->
  res.render 'person/links/histogram', {
  title: 'Links histogram'
  id: '/person/links'
  menu: menu
  loggedIn: loggedIn: req.loggedIn?
  }