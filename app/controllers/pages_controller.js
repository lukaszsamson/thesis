var locomotive = require('locomotive')
  , Controller = locomotive.Controller
  , request = require('request')
  , querystring = require('querystring');

var PagesController = new Controller();

var APP_ID = '102219526568766';
var APP_SECRET = 'ee755ea1ef4ab900bb46b497d5a93ca0';


PagesController.main = function() {
  var self = this;
  if (!this.req.session.facebookToken) {//TODO expires
    var code = this.req.query.code;
    if (!code) {
      var path = 'https://www.facebook.com/dialog/oauth?';
      var queryParams = [
        'client_id=' + APP_ID,
        'redirect_uri=' + encodeURIComponent('http://localhost:3000/'),
        'scope=' + 'read_stream',
      ];
      var query = queryParams.join('&');
      var url = path + query;
      this.redirect(url);
    }

    var path = 'https://graph.facebook.com/oauth/access_token?';
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
}

module.exports = PagesController;
