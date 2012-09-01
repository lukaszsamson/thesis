menu = require './menu'

exports.index = (req, res) ->
  res.render 'person/friends/index', {
    title: 'Friends'
    id: '/person/friends'
    menu: menu
    loggedIn: loggedIn: req.loggedIn?
  }

exports.connections = (req, res) ->
  res.render 'person/friends/connections', {
    title: 'Friends connections'
    id: '/person/friends'
    menu: menu
    loggedIn: loggedIn: req.loggedIn?
  }