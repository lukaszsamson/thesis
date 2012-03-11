var request = require('request'),
  querystring = require('querystring'),
  locomotive = require('locomotive');


function callbackRequest(url, callback) {
  request(url, function (error, response, body) {
    if (error) return callback(error);
    else if (response.statusCode != 200) return callback(new Error(body));
    return callback(null, body);
  });
}

function GraphClient(access_token) {
  this.access_token = access_token;
}

GraphClient.prototype.getLinks = function (facebookId, callback) {
  return callbackRequest(this.getLinksUrl(facebookId), function (error, body) {
    if (error) return callback(error);
    try {
      var data = JSON.parse(body).data;
      return callback(null, data);
    } catch (e) {
      return callback(e);
    }
  });
}
GraphClient.prototype.getMe = function (callback) {
  return callbackRequest(this.getMeUrl(), function (error, body) {
    if (error) return callback(error);
    try {
      var me = JSON.parse(body);
      return callback(null, me);
    } catch (e) {
      return callback(e);
    }
  });
}

GraphClient.prototype.getFriend = function (id, callback) {
  return callbackRequest(this.getFriendUrl(id), function (error, body) {
    if (error) return callback(error);
    try {
      var me = JSON.parse(body);
      return callback(null, me);
    } catch (e) {
      return callback(e);
    }
  });
}

GraphClient.prototype.getFriends = function (callback) {
  return callbackRequest(this.getFriendsUrl(), function (error, body) {
    if (error) return callback(error);
    try {
      var data = JSON.parse(body).data;
      return callback(null, data);
    } catch (e) {
      return callback(e);
    }
  });
}
GraphClient.prototype.getMutualFriends = function (facebookId, callback) {
  return callbackRequest(this.getMutualFriendsUrl(facebookId), function (error, body) {
    if (error) return callback(error);
    try {
      var data = JSON.parse(body).data;
      return callback(null, data);
    } catch (e) {
      return callback(e);
    }
  });
}

GraphClient.prototype.getMeUrl = function () {
  return 'https://graph.facebook.com/me?access_token=' + encodeURIComponent(this.access_token);
}

GraphClient.prototype.getFriendUrl = function (id) {
  return 'https://graph.facebook.com/' + encodeURIComponent(id) + '?access_token=' + encodeURIComponent(this.access_token);
}

GraphClient.prototype.getFriendsUrl = function () {
  return 'https://graph.facebook.com/me/friends?access_token=' + encodeURIComponent(this.access_token);
}

GraphClient.prototype.getMutualFriendsUrl = function (facebookId) {
  return 'https://graph.facebook.com/me/mutualfriends/' + encodeURIComponent(facebookId) + '?access_token=' + encodeURIComponent(this.access_token);
}

GraphClient.prototype.getLinksUrl = function (facebookId) {
  return 'https://graph.facebook.com/' + facebookId + '/links?access_token=' + encodeURIComponent(this.access_token);
}

function getDialogUrl() {
  var path = 'https://www.facebook.com/dialog/oauth?';
  var queryParams = ['client_id=' + locomotive.set('facebook app id'), 'redirect_uri=' + encodeURIComponent(locomotive.set('facebook redirect')), 'scope=' + 'read_stream', ];
  var query = queryParams.join('&');
  return url = path + query;
}

function getAccessTokenUrl(code) {
  var path = 'https://graph.facebook.com/oauth/access_token?';
  var queryParams = ['client_id=' + locomotive.set('facebook app id'), 'redirect_uri=' + encodeURIComponent(locomotive.set('facebook redirect')), 'client_secret=' + locomotive.set('facebook app secret'), 'code=' + encodeURIComponent(code)];
  var query = queryParams.join('&');
  return url = path + query;
}

function auth(req, res, next) {
  if (req.session.facebookToken) return next();
  var code = req.query.code;
  if (!code) return res.redirect(getDialogUrl());

  callbackRequest(getAccessTokenUrl(code), function (error, body) {
    if (error) return next(error);
    try {
      req.session.facebookToken = querystring.parse(body);
      return next();
    } catch (e) {
      return next(e);
    }
  });
}

module.exports = {
  Graph: GraphClient,
  auth: auth
}