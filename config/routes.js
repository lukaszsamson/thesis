module.exports = function routes() {
  this.root('pages#main');
  this.resources('threads');
  this.match('threads/:id/post', { controller: 'threads', action: 'post', via: 'post' });
}
