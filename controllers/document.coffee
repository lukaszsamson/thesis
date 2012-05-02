Document = require '../models/document'

exports.index = (req, res) ->
  Document.find (error, result) ->
    return res.error error if error
    res.render 'document/index',
      documents: result

exports.show = (req, res) ->
  id = req.params.id
  Document.findById id, (error, result) ->
    return res.error error if error
    return res.error new NotFound('Document #{id} not found') if not result
    res.render 'document/show',
      document: result