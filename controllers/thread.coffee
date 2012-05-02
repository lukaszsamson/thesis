Thread = require '../models/thread'
###
threads = [
  {
    id: 0,
    title: 't1',
    author: 'a1',
    body: 'fdvdf vdfv fdv fd v fdv df v  dfv'
  },
  {
    id: 1,
    title: 't2',
    author: 'a2',
    body: 'sdcdsv fdvef scsdksdc  sdc  vd s vvfv'
  },
  {
    id: 2,
    title: 't3',
    author: 'a3',
    body: 'dscqcev  ref2qf wef ref sd vcwe v rev sd cv r gv sd fwekf we fsd vrwe   fcds cve w'
  }
]
###
exports.index = (req, res) ->
  #res.render 'thread/index', threads: threads

  Thread.find (error, result) ->
    return res.error error if error
    res.render 'thread/index', (threads: result)


exports.show = (req, res) ->
  #thread = threads[req.params.id]
  #res.render 'thread/show', thread: thread
  Thread.findById req.params.id, (error, result) ->
    return res.error error if error
    res.render 'thread/show', (thread: result)

exports.create = (req, res) ->
  thread = new Thread
    title: req.body.title
    body: req.body.body
    author: req.body.author
  thread.save (error) ->
    return res.error error if error
    res.redirect 'threads'