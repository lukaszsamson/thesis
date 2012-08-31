request = require './simple-request'
querystring = require 'querystring'
Graph = require('./graph-client').Graph

validateSession = (session) -> session.facebookToken and Date.parse(session.facebookToken.expiresDate) > new Date

exports.redirector = (url) ->
  return (req, res, next) ->
    return res.redirect(url) if validateSession(req.session)
    next()

getlogOutUrl = (redirectUrl, access_token) ->
  "https://www.facebook.com/logout.php?next=#{encodeURIComponent(redirectUrl)}&access_token=#{encodeURIComponent access_token}"

exports.logOut = (req, res, next) ->
  token = req.session.facebookToken.access_token if validateSession(req.session)
  redirectURI = req.protocol + '://' + req.headers.host + "/"
  req.session.destroy (e) ->
    return next(e) if e
    res.redirect (if token then getlogOutUrl(redirectURI, token) else '/')

#TODO csrf by state param
exports.authenticate = (config) ->
  getDialogUrl = (appId, redirectUri, scope) ->
    path = 'https://www.facebook.com/dialog/oauth?'
    queryParams = [
      'client_id=' + encodeURIComponent(appId),
      'redirect_uri=' + encodeURIComponent(redirectUri),
      'scope=' + encodeURIComponent(scope)
    ]
    query = queryParams.join '&'
    path + query

  getAccessTokenUrl = (appId, redirectUri, appSecret, code) ->
    path = 'https://graph.facebook.com/oauth/access_token?'
    queryParams = [
      'client_id=' + encodeURIComponent(appId),
      'redirect_uri=' + encodeURIComponent(redirectUri),
      'client_secret=' + encodeURIComponent(appSecret),
      'code=' + encodeURIComponent(code)
    ];
    query = queryParams.join '&'
    path + query;

  return (req, res, next) ->
    #try to validate session
    if validateSession(req.session)
      req.loggedIn = true
      return next()

    #try to get api code from querystring
    redirectURI = req.protocol + '://' + req.headers.host + req.url
    code = req.query.code
    if code
      return request getAccessTokenUrl(config.appId, redirectURI, config.appSecret, code), (error, body) ->
        return next error if error
        try
          req.session.facebookToken = querystring.parse body
          d = new Date
          d.setSeconds(d.getSeconds() + req.session.facebookToken.expires)
          req.session.facebookToken.expiresDate = d
          (new Graph(req.session.facebookToken.access_token)).getAppUser((error, user) ->
            return next error if error
            req.session.facebookData = user
            return res.redirect redirectURI.split('?')[0]
          )
        catch e
          return next e

    #redirect to oauth dialog
    return res.redirect getDialogUrl(config.appId, redirectURI, config.scope)