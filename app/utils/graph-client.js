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
  return promissedRequest(getLinksUrl(id))
  .then(function(body) {
    return JSON.parse(body).data;
  });
}
GraphClient.prototype.getFriends = function() {
  return promissedRequest(getFriendsUrl())
  .then(function(body) {
    return JSON.parse(body).data;
  });
}

GraphClient.prototype.getAccessToken = function(code) {
  return promissedRequest(getAccessTokenUrl(code))
  .then(function(body) {
    return querystring.parse(body);
  });
}

GraphClient.prototype.getDialogUrl = function() {
  var path = 'https://www.facebook.com/dialog/oauth?';
  var queryParams = [
    'client_id=' + locomotive.set('facebook app id'),
    'redirect_uri=' + encodeURIComponent('http://localhost:3000/'),
    'scope=' + 'read_stream',
  ];
  var query = queryParams.join('&');
  return url = path + query;
}

GraphClient.prototype.getAccessTokenUrl = function(code) {
  var path = 'https://graph.facebook.com/oauth/access_token?';
  var queryParams = [
    'client_id=' + locomotive.set('facebook app id'),
    'redirect_uri=' + encodeURIComponent('http://localhost:3000/'),
    'client_secret=' + locomotive.set('facebook app secret'),
    'code=' + encodeURIComponent(code)
  ];
  var query = queryParams.join('&');
  return url = path + query;
}

GraphClient.prototype.getFriendsUrl = function() {
  return 'https://graph.facebook.com/me/friends?access_token='
          + encodeURIComponent(this.access_token);
}

GraphClient.prototype.getLinksUrl = function(id) {
  return 'https://graph.facebook.com/' + id + '/links?access_token='
          + encodeURIComponent(this.access_token);
}

module.exports = GraphClient;