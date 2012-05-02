request = require 'request'

module.exports = (url, callback) ->
  try
    request {
      uri: url,
      timeout: 10000
    }, (error, response, body) ->
      return callback error if error
      if response.statusCode != 200
        console.log('%d from %s', response.statusCode, url)
        return callback null, null
      return callback null, body
  catch e
    callback e