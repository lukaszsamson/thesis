request = require 'request'

module.exports = (url, callback) ->
  request url, (error, response, body) ->
    return callback error if error
    if response.statusCode != 200
      return callback new Error body
    return callback null, body