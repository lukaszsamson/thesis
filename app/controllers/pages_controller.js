var locomotive = require('locomotive')
  , Controller = locomotive.Controller
  , request = require('request')
  , querystring = require('querystring')
  , async = require("async")
  , Q = require("q");

var PagesController = new Controller();

var APP_ID = '102219526568766';
var APP_SECRET = 'ee755ea1ef4ab900bb46b497d5a93ca0';


function getDialogUrl() {
  var path = 'https://www.facebook.com/dialog/oauth?';
  var queryParams = [
    'client_id=' + APP_ID,
    'redirect_uri=' + encodeURIComponent('http://localhost:3000/'),
    'scope=' + 'read_stream',
  ];
  var query = queryParams.join('&');
  return url = path + query;
}

function getAccessTokenUrl(code) {
  var path = 'https://graph.facebook.com/oauth/access_token?';
  var queryParams = [
    'client_id=' + APP_ID,
    'redirect_uri=' + encodeURIComponent('http://localhost:3000/'),
    'client_secret=' + APP_SECRET,
    'code=' + encodeURIComponent(code)
  ];
  var query = queryParams.join('&');
  return url = path + query;
}

function getFriendsUrl(token) {
  return 'https://graph.facebook.com/me/friends?access_token='
          + encodeURIComponent(token);
}

function getLinksUrl(id, token) {
  return 'https://graph.facebook.com/' + id + '/links?access_token='
          + encodeURIComponent(token);
}

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


PagesController.main = function() {
  var self = this;
  var code = this.req.query.code;

  if (!self.req.session.facebookToken && !code) {
      this.redirect(getDialogUrl());
    } else {

      Q.when((function() {

        if (self.req.session.facebookToken)
          return self.req.session.facebookToken.access_token;

        return Q.when(promissedRequest(getAccessTokenUrl(code))).
          then(function(body) {
            var result = self.req.session.facebookToken = querystring.parse(body);
            return result.access_token;
          });
      })())
      .then(function(access_token) {
        return promissedRequest(getFriendsUrl(access_token));
      })
      .then(function(body) {
        self.title = 'Locomotive';
        var friends = JSON.parse(body).data;
        self.render({
          friends: friends
        });
      })
      .fail(function(error) {
        self.error(error);
      });
  }
}

PagesController.friend = function() {
  var self = this;
  var facebookId = self.req.params.id;
  self.getLinks(facebookId)
  .then(function(links) {
    self.render({facebookId: facebookId, links: links});
  })
  .fail(function(error) {
    self.error(error);
  });
}

PagesController.getToken = function() {
  return this.req.session.facebookToken.access_token;
}

PagesController.getLinks = function(facebookId) {
  var self = this;
  return Q.when(facebookId)
  .then(function(id) {
    return promissedRequest(getLinksUrl(id, self.getToken()));
  })
  .then(function(body) {
    return JSON.parse(body).data;
  });
}

PagesController.getFriends = function() {
  friends.forEach(function(friend) {
    new Person({
      name: friend.name,
      facebookId: friend.id,
      queriedDate: new Date(),
      links: null
    }).save();
  });
}





// PagesController.main = function() {
//   var self = this;
//   //if (!this.req.session.facebookToken) {//TODO expires
//     var code = this.req.query.code;
//     if (!code) {
//       this.redirect(getDialogUrl());
//     } else {
//     async.waterfall([
//       function(callback) {
//         request(getAccessTokenUrl(code), function (error, response, body) {
//           if (error) {
//             callback(error);
//           } else if (response.statusCode != 200) {
//             callback({code: response.statusCode, body: body});
//           } else {
//             console.log(body);
//             var result = self.req.session.facebookToken = querystring.parse(body);
//             callback(null, result.access_token);
//           }
//         });
//       },
//       function(token, callback) {
//         request(getFriendsUrl(token), function (error, response, body) {
//           if (error) {
//             callback(error);
//           } else if (response.statusCode != 200) {
//             callback({code: response.statusCode, body: body});
//           } else {
//             callback(null, JSON.parse(body).data)
//           }
//         });        
//       }
//       ]
//     , function(error, results) {
//       if (error) {
//         console.log(error);
//         throw error;
//       } else {
//         self.title = 'Locomotive';
//         self.render({
//           friends: results
//         });
//       }
//     });
// }
// };



/*    var path = 'https://graph.facebook.com/oauth/access_token?';
    var queryParams = [
      'client_id=' + APP_ID,
      'redirect_uri=' + encodeURIComponent('http://localhost:3000/'),
      'client_secret=' + APP_SECRET,
      'code=' + encodeURIComponent(code)
    ];
    var query = queryParams.join('&');
    var url = path + query;
    console.log(url);
    request(url, function (error, response, body) {
      if (!error && response.statusCode == 200) {
        console.log(body);
        self.req.session.facebookToken = querystring.parse(body);


        request('https://graph.facebook.com/me/friends?access_token='
          + encodeURIComponent(self.req.session.facebookToken.access_token), function (error1, response1, body1) {
          if (!error1 && response1.statusCode == 200) {
            self.title = 'Locomotive';
            self.render({
              friends: JSON.parse(body1).data
            });
          }
        });
      }
    });
  } else {
  request('https://graph.facebook.com/me/friends?access_token='
          + encodeURIComponent(self.req.session.facebookToken.access_token), function (error1, response1, body1) {
          if (!error1 && response1.statusCode == 200) {
            self.title = 'Locomotive';
            self.render({
              friends: JSON.parse(body1).data
            });
          }
        });
}
*/
//}

module.exports = PagesController;
