request = require './simple-request'

class GraphClient
  constructor: (@access_token) ->

  getLinks: (facebookId, callback) ->
    request @getLinksUrl(facebookId), (error, body) ->
      return callback error if error
      try
        data = JSON.parse(body).data
        callback null, data
      catch e
        callback e
        
  getLikes: (facebookId, callback) ->
    request @getLikesUrl(facebookId), (error, body) ->
      return callback error if error
      try
        data = JSON.parse(body).data
        callback null, data
      catch e
        callback e

  getAppUser: (callback) ->
    request @getAppUserUrl(), (error, body) ->
      return callback error if error
      try
        me = JSON.parse(body);
        return callback null, me
      catch e
        return callback e

  getFriend: (id, callback) ->
    request @getFriendUrl(id), (error, body) ->
      return callback error if error
      try
        me = JSON.parse body
        return callback null, me
      catch e
        return callback e

  getFriends: (callback) ->
    request(@getFriendsUrl(), (error, body) ->
      return callback error if error
      try
        data = JSON.parse(body).data;
        return callback null, data
      catch e
        return callback e
    )

  getMutualFriends: (facebookId, callback) ->
    request(@getMutualFriendsUrl(facebookId), (error, body) ->
      return callback(error) if error
      try
        data = JSON.parse(body).data;
        return callback(null, data)
      catch e
        return callback(e)
    )

  getAppUserUrl: ->
    "https://graph.facebook.com/me?access_token=#{encodeURIComponent @access_token}"

  getFriendUrl: (id) ->
    "https://graph.facebook.com/#{encodeURIComponent(id)}?access_token=#{encodeURIComponent @access_token}"

  getFriendsUrl: ->
    "https://graph.facebook.com/me/friends?access_token=#{encodeURIComponent @access_token}"

  getMutualFriendsUrl: (facebookId) ->
    "https://graph.facebook.com/me/mutualfriends/#{encodeURIComponent(facebookId)}?access_token=#{encodeURIComponent @access_token}"

  getLinksUrl: (facebookId) ->
    "https://graph.facebook.com/#{encodeURIComponent(facebookId)}/links?access_token=#{encodeURIComponent @access_token}"

  getLikesUrl: (facebookId) ->
    "https://graph.facebook.com/#{encodeURIComponent(facebookId)}/likes?access_token=#{encodeURIComponent @access_token}"
    




module.exports = {
  Graph: GraphClient
}
