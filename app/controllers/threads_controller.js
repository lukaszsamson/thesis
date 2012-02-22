var locomotive = require('locomotive')
  , Controller = locomotive.Controller;

var Thread = require('../models/thread.js');
var Post = require('../models/post.js');

var ThreadsController = new Controller();

ThreadsController.index = function() {
  var self = this;
  Thread.find(function(err, threads) {
    self.render({threads: threads, title: "testing"});
  });
}

ThreadsController.new = function() {
  this.title = 'Locomotive'
  this.render();
}

ThreadsController.create = function() {
  new Thread({title: this.req.body.title, author: this.req.body.author}).save();
  this.redirect(this.urlFor({ action: 'index' }));
}

ThreadsController.show = function() {
    var self = this;
    Thread.findOne({_id: this.req.params.id}, function(error, thread) {
        console.log(thread.posts.length);
        self.render({thread: thread, title: "testing"});
        //var posts = Post.find({thread: thread._id}, function(error, posts) {
        //  res.send([{thread: thread, posts: posts}]);
        //});
    })
}

ThreadsController.edit = function() {
  var self = this;
    Thread.findOne({_id: this.req.params.id}, function(error, thread) {
        thread.posts.append(new Post({body: self.req.body.body}));
        thread.save();
        this.redirect(this.urlFor({ action: 'show', id: thread._id }));
        //var posts = Post.find({thread: thread._id}, function(error, posts) {
        //  res.send([{thread: thread, posts: posts}]);
        //});
    })
}

ThreadsController.post = function() {
  var self = this;
  var id = this.req.params.id;
  //return self.redirect(self.urlFor({ action: 'show', id: id }));
  console.log('in post');
  Thread.update({_id: id}, {$push: {posts: new Post({body: self.req.body.body})}}
  , {multi: false}
  , function(error, numAffected) {
  console.log('in callback');
  console.log(error);
  console.log(numAffected);
  if (error)
    self.res.send(error);
    self.redirect(self.urlFor({ action: 'show', id: id }));
  });
    //Thread.findOne({_id: this.req.params.id}, function(error, thread) {
      //  thread.posts.append(new Post({body: self.req.body.body}));
        //thread.save();
        //this.redirect(this.urlFor({ action: 'show', id: thread._id }));
        //var posts = Post.find({thread: thread._id}, function(error, posts) {
        //  res.send([{thread: thread, posts: posts}]);
        //});
    //})
}

ThreadsController.update = function() {
  this.title = 'Locomotive'
  this.render();
}

ThreadsController.destroy = function() {
  this.title = 'Locomotive'
  this.render();
}

module.exports = ThreadsController;
