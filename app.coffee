express = require 'express'
http = require 'http'

mongoose = require('mongoose')

db = mongoose.connect 'mongodb://localhost/test'

app = express()
#app.use assets()
app.set 'view engine', 'jade'
app.set 'facebook app id', '102219526568766'
app.set 'facebook app secret', 'ee755ea1ef4ab900bb46b497d5a93ca0'
app.set 'facebook redirect', 'http://localhost:3000/'
app.set 'facebook scope', 'read_stream'
app.use express.cookieParser 'shoop da woop'
app.use express.session()

app.use express.logger()
app.use express.bodyParser()

auth = (require './utils/graph-client').facebookAuth
  appId: '102219526568766'
  appSecret: 'ee755ea1ef4ab900bb46b497d5a93ca0'
  redirectUri: 'http://localhost:3000/person'
  scope: 'read_stream'

app.get '/', (req, resp, error) ->
  e = new Error("test")
  e.status = 404
  error(e)


person = require './controllers/person'
app.get '/person', auth, person.index
app.post '/person/getData', auth, person.getData
app.post '/person/countLinks', auth, person.countLinks
app.get '/person/links', auth, person.links
app.post '/person/countLikes/byName', auth, person.countLikesByName
app.get '/person/likes/byName', auth, person.likesByName
app.post '/person/countLikes/byCategory', auth, person.countLikesByCategory
app.get '/person/likes/byCategory', auth, person.likesByCategory

app.use express.static __dirname + '/public'

app.use express.errorHandler()

server = http.createServer(app)
server.listen process.env.VMC_APP_PORT or 3000, ->
  console.log "Listening on #{server.address().address}:#{server.address().port}"
