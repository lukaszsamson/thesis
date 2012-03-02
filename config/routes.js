module.exports = function routes() {
  this.root('pages#main');
  this.resources('threads');
  this.match('threads/:id/post', { controller: 'threads', action: 'post', via: 'post' });
  this.match('friends/:id', { controller: 'pages', action: 'friend', via: 'get' });
  this.match('friends', { controller: 'pages', action: 'friends', via: 'get' });
}
