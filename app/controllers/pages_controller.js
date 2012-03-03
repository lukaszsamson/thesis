var locomotive = require('locomotive')
  , Controller = locomotive.Controller
  , Graph = require('../utils/graph-client.js').Graph
  , Q = require('q')
  , Person = require('../models/person.js')
  , Link = require('../models/link.js');


var kue = require('kue');

// create our job queue

var jobs = kue.createQueue()
  , Job = kue.Job;

var PagesController = new Controller();

PagesController.test = function() {
  var self = this;
  self.title = 'thest';
  getFriends(self.getToken());

  self.render({
    token: self.getToken()
  });
}

PagesController.main = function() {
  var self = this;


  return;
  var code = this.req.query.code;


  if (!self.req.session.facebookToken && !code) {
      this.redirect((new GraphClient).getDialogUrl());
    } else {
      var access_token = 
      Q.when((function() {

      })())
      .then(function(access_token) {
        return promissedRequest(getFriendsUrl(access_token));
      })
      .then(function(body) {
        self.title = 'Locomotive';
        var friends = JSON.parse(body).data;

        friends.forEach(function(friend) {
          create(friend, self.getToken());
        });

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
  (new GraphClient(self.getToken()))
  .getLinks(facebookId)
  .then(function(links) {
    self.render({facebookId: facebookId, links: links});
  })
  .fail(function(error) {
    self.error(error);
  });
}

PagesController.friends = function() {
  var self = this;
  (new GraphClient(self.getToken()))
  .getFriends()
  .then(function(friends) {
    friends.forEach(function(friend) {
          create(friend, self.getToken());
    });

    self.render({
      friends: friends
    });
  })
  .fail(function(error) {
    self.error(error);
  });
}

PagesController.getToken = function() {
  var self = this;
  if (self.req.session.facebookToken)
    return self.req.session.facebookToken.access_token;
}
/*
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
*/

function getFriends(access_token) {
  console.log('Creating getFriends job');
  jobs.create('get friends', {
      title: 'Getting friends'
    , access_token: access_token
    //, facebookId: facebookId
  }).save();
}


function getLinks(friend, access_token) {
  console.log('Creating getLinks job for %s', friend.name);
  jobs.create('get links', {
      title: 'Getting links submitted by ' + friend.name
    , friendFacebookId: friend.id
    , friendName: friend.name
    , access_token: access_token
    //, facebookId: facebookId
  }).save();
}

jobs.process('get friends', 3, function(job, done) {
  (new Graph(job.data.access_token))
  .getFriends()
  .then(function(friends) {
    friends.forEach(function(friend) {
      var model = new Person({
        name: friend.name,
        facebookId: friend.id,
        queriedDate: new Date(),
        links: []
      }).save(function(error) {
        if (error) {
          console.log("Save to db failed");
          return;
        }
        getLinks(friend, job.data.access_token);
      });
    });
    done();
  })
  .fail(function(error) {
    console.log('Error while getting friends');
    console.log(error);
    done(error);
  })
});

jobs.process('get links', 3, function(job, done) {
  (new Graph(job.data.access_token)).getLinks(job.data.friendFacebookId)
  .then(function(links) {
    console.log('got %d links by %s', links.length, job.data.friendName);
    Person.update({
      facebookId: job.data.friendFacebookId
    }, {
      $push: {
        links: links.map(function(link) {
          return new Link({
            url: link.url,
          });
        })
      }
    }, {
      multi: false
    }, function(error, numAffected) {
      console.log('in callback');
      console.log(error);
      console.log(numAffected);
      done(error);
    });
  })
  .fail(function(error) {
    console.log('Error while getting links by %s', job.data.friendName);
    console.log(error);
    done(error);
  });
});

jobs.on('job complete', function(id){
  Job.get(id, function(err, job){
    if (err) {
      console.log('Error while getting job #%d', job.id);
      console.log(err);
      return;
    }
    job.remove(function(err){
      if (err) {
        console.log('Error while getting job #%d', job.id);
        console.log(err);
        return;
      }
      console.log('removed completed job #%d', job.id);
    });
  });
});

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
