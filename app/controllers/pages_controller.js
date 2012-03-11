var locomotive = require('locomotive'),
  Controller = locomotive.Controller,
  Graph = require('../utils/graph-client.js').Graph,
  Person = require('../models/person.js'),
  Friend = require('../models/friend.js'),
  Link = require('../models/link.js'),
  util = require('util'),
  async = require('async');


var kue = require('kue');

// create our job queue
var jobs = kue.createQueue(),
  Job = kue.Job;

var PagesController = new Controller();

PagesController.test = function () {
  var self = this;
  self.title = 'thest';
  getMe(self.getToken(), function (e) {
    if (e) return self.error(e);
    self.render({
      token: self.getToken()
    });
  });
}

function NotFound(msg) {
  Error.call(this);
  Error.captureStackTrace(this, arguments.callee);
  this.name = 'NotFound';
  this.message = msg;
}

NotFound.prototype.__proto__ = Error.prototype;

PagesController.main = function () {
  var self = this;


  return;
  var code = this.req.query.code;


  if (!self.req.session.facebookToken && !code) {
    this.redirect((new GraphClient).getDialogUrl());
  } else {
    var access_token = Q.when((function () {

    })()).then(function (access_token) {
      return promissedRequest(getFriendsUrl(access_token));
    }).then(function (body) {
      self.title = 'Locomotive';
      var friends = JSON.parse(body).data;

      friends.forEach(function (friend) {
        create(friend, self.getToken());
      });

      self.render({
        friends: friends
      });
    }).fail(function (error) {
      self.error(error);
    });
  }
}

PagesController.friend = function () {
  var self = this;
  var facebookId = self.req.params.id;
  Person.findOne({
    facebookId: facebookId
  }, function (error, result) {
    if (error) return self.error(error);
    if (!result) return self.error(new NotFound(util.format('Friend with id %s does not exist', facebookId)));
    self.render({
      facebookId: facebookId,
      links: result.links
    });
  });
}

PagesController.friends = function () {
  var self = this;
  Person.find(function (error, result) {
    if (error) return self.error(error);
    self.render({
      friends: result
    });
  });
}

PagesController.getToken = function () {
  var self = this;
  if (self.req.session.facebookToken) return self.req.session.facebookToken.access_token;
}

function getMe(access_token, done) {
  console.log('Creating getMe job');
  jobs.create('get me', {
    title: 'Getting me',
    access_token: access_token
  }).attempts(3).save(done);
}

function getFriend(me, friend, access_token, done) {
  console.log('Creating getFriend job');
  jobs.create('get friend', {
    title: 'Getting friend ' + friend.name,
    me: me,
    friend: friend,
    access_token: access_token
  }).attempts(3).save(done);
}

function getFriends(me, access_token, done) {
  console.log('Creating getFriends job');
  jobs.create('get friends', {
    title: 'Getting friends',
    me: me,
    access_token: access_token
  }).attempts(3).save(done);
}

function getMutualFriends(friend, access_token, done) {
  console.log('Creating getMutualFriends job for %s', friend.name);
  jobs.create('get mutual friends', {
    title: 'Getting mutual friends of ' + friend.name,
    friend: friend,
    access_token: access_token
  }).attempts(3).save(done);
}

function getMyLinks(me, access_token, done) {
  console.log('Creating getLinks job for %s', me.name);
  jobs.create('get my links', {
    title: 'Getting links submitted by ' + me.name,
    me: me,
    access_token: access_token
  }).attempts(3).save(done);
}

function getLinks(friend, access_token, done) {
  console.log('Creating getLinks job for %s', friend.name);
  jobs.create('get links', {
    title: 'Getting links submitted by ' + friend.name,
    friend: friend,
    access_token: access_token
  }).attempts(3).save(done);
}


jobs.process('get me', 3, function (job, done) {
  async.waterfall([
    function(c0) {
      (new Graph(job.data.access_token)).getMe(c0);
    },
    function(me, c0) {
      async.series([
        function(c1) {
          saveOrUpdatePerson(me, c1);
        },
        function(c1) {
          async.parallel([
            function (c2) {
              getMyLinks(me, job.data.access_token, c2);
            }, function (c2) {
              getFriends(me, job.data.access_token, c2);
            }], c1);
        }], c0);
    }], done);
});

jobs.process('get friend', 3, function (job, done) {
  async.waterfall([
    function(c0) {
      (new Graph(job.data.access_token)).getFriend(job.data.friend.id, c0);
    },
    function(friend, c0) {
      async.series([
        function(c1) {
          saveOrUpdateFriend(job.data.me, friend, c1);
        },
        function(c1) {
          async.parallel([
            function (c2) {
              getLinks(friend, job.data.access_token, c2);
            }, function (c2) {
              getMutualFriends(friend, job.data.access_token, c2);
            }], c1);
        }], c0);
    }], done);
});

jobs.process('get friends', 3, function (job, done) {
  async.waterfall([
    function(c0) {
      (new Graph(job.data.access_token)).getFriends(c0);
    },
    function(friends, c0) {
      async.series([
        function(c1) {
          updateFrineds(job.data.me.id, friends, c1);
        },
        function(c1) {
          async.forEach(friends, function (friend, c2) {
            getFriend(job.data.me, friend, job.data.access_token, c2);
          }, c1);
        }], c0);
    }], done);
});

jobs.process('get mutual friends', 3, function (job, done) {
  async.waterfall([
    function(c0) {
      (new Graph(job.data.access_token)).getMutualFriends(job.data.friend.id, c0);
    },
    function(mutualFriends, c0) {
      updateMutualFrineds(job.data.friend.id, mutualFriends, c0);
    }], done);
});

jobs.process('get my links', 3, function (job, done) {
  async.waterfall([
    function (c0) {
      (new Graph(job.data.access_token)).getLinks(job.data.me.id, c0);
    },
    function (links, c0) {
      updatePersonLinks(job.data.me.id, links, c0);
    }], done);
});

jobs.process('get links', 3, function (job, done) {
  async.waterfall([
    function (c0) {
      (new Graph(job.data.access_token)).getLinks(job.data.friend.id, c0);
    },
    function (links, c0) {
      updateFriendLinks(job.data.friend.id, links, c0);
    }], done);
});

jobs.on('job complete', function (id) {
  return;
  Job.get(id, function (err, job) {
    if (err) {
      console.log('Error while getting job #%d', job.id);
      console.log(err);
      return;
    }
    job.remove(function (err) {
      if (err) {
        console.log('Error while getting job #%d', job.id);
        console.log(err);
        return;
      }
      //console.log('removed completed job #%d', job.id);
    });
  });
});


function saveOrUpdateFriend(me, friend, done) {
  Friend.findOne({
    facebookId: friend.id
  }, function (error, result) {
    if (error) return done(error);
    if (!result) {
      var model = new Friend({
        name: friend.name,
        facebookId: friend.id,
        ownerFacebookId: me.id,
        updatedDate: new Date(),
        links: [],
        mutualFriends: []
      }).save(done);
    } else {
      result.name = friend.name;
      result.updatedDate = new Date();
      result.links = [];
      result.mutualFriends = [];
      result.save(done);
    }
  });
}


function saveOrUpdatePerson(me, done) {
  Person.findOne({
    facebookId: me.id
  }, function (error, person) {
    if (error) return done(error);
    if (!person) {
      var model = new Person({
        name: me.name,
        facebookId: me.id,
        updatedDate: new Date(),
        links: [],
        friends: []
      }).save(done);
    } else {
      person.name = me.name;
      person.updatedDate = new Date();
      person.links = [];
      person.friends = [];
      person.save(done);
    }
  });
}

function updatePersonLinks(id, links, done) {
  Person.update({
      facebookId: id
    }, {
      $pushAll: {
        links: links.map(function (link) {
          return new Link({
            url: link.link,
            facebookId: link.id
          });
        })
      }
    }, {
      multi: false
    }, done);
}

function updateFriendLinks(id, links, done) {
  Friend.update({
      facebookId: id
    }, {
      $pushAll: {
        links: links.map(function (link) {
          return new Link({
            url: link.link,
            facebookId: link.id
          });
        })
      }
    }, {
      multi: false
    }, done);
}

function updateFrineds(id, friends, done) {
  Person.update({
      facebookId: id,
    }, {
      $set: {
      friends: friends.map(function(friend) {
        return {
          facebookId: friend.id,
          name: friend.name
        };
      })
    }}, {
      multi: false
    }, done);
}

function updateMutualFrineds(id, mutualFriends, done) {
  Friend.update({
      facebookId: id,
    }, {
      $set: {
      mutualFriends: mutualFriends.map(function(mutualFriend) {
        return {
          facebookId: mutualFriend.id,
          name: mutualFriend.name
        };
      })
    }}, {
      multi: false
    }, done);
}


module.exports = PagesController;