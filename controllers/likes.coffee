menu = require './menu'

exports.index = (req, res, next) ->
  res.render('person/likes/index', {
    title: 'Likes'
    id: '/person/likes'
    menu: menu
    loggedIn: loggedIn: req.loggedIn?
  })

exports.cloud = (req, res) ->
  res.render 'person/likes/cloud', {
    title: 'Likes cloud'
    id: '/person/likes'
    menu: menu
    loggedIn: loggedIn: req.loggedIn?
  }

exports.histogram = (req, res) ->
  res.render 'person/likes/histogram', {
  title: 'Likes histogram'
  id: '/person/likes'
  menu: menu
  loggedIn: loggedIn: req.loggedIn?
  }

exports.flow = (req, res) ->
  res.render 'person/likes/flow', {
  title: 'Likes flow'
  id: '/person/likes'
  menu: menu
  loggedIn: loggedIn: req.loggedIn?
  }