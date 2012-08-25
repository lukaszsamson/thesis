exports.index = (req, res) ->
  res.render 'index', {
  title: 'Welcome'
  id: '/'
  menu: {}
  loggedIn: req.loggedIn?
  }

