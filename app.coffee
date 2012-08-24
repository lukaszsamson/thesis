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

app.use (require './utils/graph-client').facebookAuth
  appId: '102219526568766'
  appSecret: 'ee755ea1ef4ab900bb46b497d5a93ca0'
  redirectUri: 'http://localhost:3000/person'
  scope: 'read_stream'

app.get '/', (req, resp) ->
  resp.render 'index'


person = require './controllers/person'
app.get '/person', person.index
app.post '/person/getData', person.getData
app.post '/person/countLinks', person.countLinks
app.get '/person/links', person.links
app.post '/person/countLikes/byName', person.countLikesByName
app.get '/person/likes/byName', person.likesByName
app.post '/person/countLikes/byCategory', person.countLikesByCategory
app.get '/person/likes/byCategory', person.likesByCategory

app.use express.static __dirname + '/public'
app.use express.errorHandler
  dumpExceptions: true
  showStack: true

server = http.createServer(app)
server.listen process.env.VMC_APP_PORT or 3000, ->
  console.log "Listening on #{server.address().address}:#{server.address().port}"
