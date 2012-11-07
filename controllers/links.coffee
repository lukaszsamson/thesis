menu = require './menu'
Person = require '../models/person'

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

getLinks = (friends) ->
  links = {}
  for k, v of friends
    v.links.forEach (l) ->
      if links[l]
        links[l]++
      else
        links[l] = 1
  res = []
  for l, t of links
    res.push(l) if t > 1
  return res

getData = (friends, links) ->
  row = ['p1', 'p2']
  for i in [1..links.length]
    row.push("p1_l#{i}")
  for i in [1..links.length]
    row.push("p2_l#{i}")
  row.push('f')
  data = [row]
  for k1, v1 of friends
    for k2, v2 of friends
      if k1 != k2
        row = [k1,k2]
        for l in links
          row.push(if v1.links.indexOf(l) != -1 then 1 else 0)
        for l in links
          row.push(if v2.links.indexOf(l) != -1 then 1 else 0)
        row.push(if v1.friends.indexOf(k2) != -1 then 1 else 0)
        data.push(row)
  return data

exports.logisticRegression = (req, res, next) ->
  Person.mapReduceResults 'linksLogisticRegression', req.session.facebookData.id, (e, results) ->
    return next(e) if e
    if not results
      error = new Error("Not found")
      error.status = 404
      return next(error)

    links = getLinks(results.value)

    data = getData(results.value, links)

    buf = ''
    for r in data
      for i in [0...r.length-1]
        buf += r[i] + ','
      buf += r[r.length-1] + '\n'

    res.set('Content-Type', 'text/plain')
    res.send(buf)
