request = require './simple-request'
querystring = require 'querystring'

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
    request @getFriendsUrl(), (error, body) ->
      return callback error if error
      try
        data = JSON.parse(body).data;
        return callback null, data
      catch e
        return callback e

  getMutualFriends: (facebookId, callback) ->
    request @getMutualFriendsUrl(facebookId), (error, body) ->
      return callback error if error
      try
        data = JSON.parse(body).data;
        return callback null, data
      catch e
        return callback e

  getAppUserUrl: ->
    'https://graph.facebook.com/me?access_token=' + encodeURIComponent @access_token

  getFriendUrl: (id) ->
    'https://graph.facebook.com/' + encodeURIComponent(id) + '?access_token=' + encodeURIComponent @access_token

  getFriendsUrl: ->
    'https://graph.facebook.com/me/friends?access_token=' + encodeURIComponent @access_token

  getMutualFriendsUrl: (facebookId) ->
    'https://graph.facebook.com/me/mutualfriends/' + encodeURIComponent(facebookId) + '?access_token=' + encodeURIComponent @access_token

  getLinksUrl: (facebookId) ->
    'https://graph.facebook.com/' + encodeURIComponent(facebookId) + '/links?access_token=' + encodeURIComponent @access_token




facebookAuth = (config) ->
  getDialogUrl = (appId, redirectUri, scope) ->
    path = 'https://www.facebook.com/dialog/oauth?'
    queryParams = ['client_id=' + encodeURIComponent(appId), 'redirect_uri=' + encodeURIComponent(redirectUri), 'scope=' + encodeURIComponent(scope), ];
    query = queryParams.join '&'
    path + query

  getAccessTokenUrl = (appId, redirectUri, appSecret, code) ->
    path = 'https://graph.facebook.com/oauth/access_token?'
    queryParams = ['client_id=' + encodeURIComponent(appId), 'redirect_uri=' + encodeURIComponent(redirectUri), 'client_secret=' + encodeURIComponent(appSecret), 'code=' + encodeURIComponent(code)];
    query = queryParams.join '&'
    path + query;

  auth = (req, res, next) ->
    if req.session.facebookToken
      return next()
    code = req.query.code
    if not code
      return res.redirect getDialogUrl(config.appId, config.redirectUri, config.scope)

    request getAccessTokenUrl(config.appId, config.redirectUri, config.appSecret, code), (error, body) ->
      return next error if error
      try
        req.session.facebookToken = querystring.parse body
        return next()
      catch e
        return next e

module.exports = {
  Graph: GraphClient,
  facebookAuth: facebookAuth
}