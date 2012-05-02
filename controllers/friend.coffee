
Person = require '../models/person'

exports.index = (req, res) ->
  Person.find (error, result) ->
    return self.error error if error
    res.render 'friend/index', (friends: result)
