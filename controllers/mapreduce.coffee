Transforms = require('../models/query')
jobs = require('../utils/jobs')
Person = require '../models/person'

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