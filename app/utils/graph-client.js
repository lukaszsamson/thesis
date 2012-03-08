var request = require('request')
  , querystring = require('querystring')
  , Q = require("q")
  , locomotive = require('locomotive');


function promissedRequest(url) {
  var deferred = Q.defer();

  request(url, function(error, response, body) {
    if (error) {
      deferred.reject(error);
    } else if(response.statusCode != 200) {
      deferred.reject(new Error(body));
    } else {
      deferred.resolve(body);
    }
  });
  return deferred.promise;
}


function GraphClient(access_token) {
  this.access_token = access_token;
}

GraphClient.prototype.getLinks = function(facebookId) {
  return promissedRequest(this.getLinksUrl(facebookId))
  .then(function(body) {
    return JSON.parse(body).data;
  });
}
GraphClient.prototype.getFriends = function() {
  return promissedRequest(this.getFriendsUrl())
  .then(function(body) {
    return JSON.parse(body).data;
  });
}
GraphClient.prototype.getMutualFriends = function(facebookId) {
  return promissedRequest(this.getMutualFriendsUrl(facebookId))
  .then(function(body) {
    return JSON.parse(body).data;
  });
}
 

GraphClient.prototype.getFriendsUrl = function() {
  return 'https://graph.facebook.com/me/friends?access_token='
          + encodeURIComponent(this.access_token);
}

GraphClient.prototype.getMutualFriendsUrl = function(facebookId) {
  return 'https://graph.facebook.com/me/mutualfriends/' + encodeURIComponent(facebookId) + '?access_token='
          + encodeURIComponent(this.access_token);
}

GraphClient.prototype.getLinksUrl = function(facebookId) {
  return 'https://graph.facebook.com/' + facebookId + '/links?access_token='
          + encodeURIComponent(this.access_token);
}

function getDialogUrl() {
  var path = 'https://www.facebook.com/dialog/oauth?';
  var queryParams = [
    'client_id=' + locomotive.set('facebook app id'),
    'redirect_uri=' + encodeURIComponent(locomotive.set('facebook redirect')),
    'scope=' + 'read_stream',
  ];
  var query = queryParams.join('&');
  return url = path + query;
}

function getAccessTokenUrl(code) {
  var path = 'https://graph.facebook.com/oauth/access_token?';
  var queryParams = [
    'client_id=' + locomotive.set('facebook app id'),
    'redirect_uri=' + encodeURIComponent(locomotive.set('facebook redirect')),
    'client_secret=' + locomotive.set('facebook app secret'),
    'code=' + encodeURIComponent(code)
  ];
  var query = queryParams.join('&');
  return url = path + query;
}

function auth(req, res, next) {
    if (req.session.facebookToken)
      return next();
    var code = req.query.code;
    if (!code)
      return res.redirect(getDialogUrl());

    promissedRequest(getAccessTokenUrl(code))
    .then(function(body) {
      req.session.facebookToken = querystring.parse(body);
      next();
    })
    .fail(function(error) {
      next(error);  
    });
  }

module.exports = {
  Graph: GraphClient,
  auth: auth
}