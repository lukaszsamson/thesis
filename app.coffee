express = require 'express'
http = require 'http'

mongoose = require('mongoose')
RedisStore = require('connect-redis')(express)

db = mongoose.connect 'mongodb://localhost/test'

app = express()


app.set 'view engine', 'jade'
cookieParser = express.cookieParser 'shoop da woop'
app.use cookieParser
sessionStore = new RedisStore(
  #host: 'localhost'
  #port: ''
  ttl: 3600 # 1 hour
)
app.use express.session({
  cookie:
    path: '/'
    httpOnly: true
    maxAge: 3600000 # 1 hour
  store: sessionStore
})

app.use express.logger()
app.use express.bodyParser()

oauthClient = require './utils/oauth-client'
auth = oauthClient.authenticate
  appId: '102219526568766'
  appSecret: 'ee755ea1ef4ab900bb46b497d5a93ca0'
  scope: 'read_stream'

index = require './controllers/index'
app.get '/', oauthClient.redirector('/person'), index.index
app.post '/logOut', oauthClient.logOut

person = require './controllers/person'
app.get '/person', auth, person.index
app.post '/person/getData', auth, person.getData
app.post '/person/countLinks', auth, person.countLinks
app.get '/person/links', auth, person.links
app.post '/person/countLikes/byName', auth, person.countLikesByName
app.get '/person/likes/byName', auth, person.likesByName
app.post '/person/countLikes/byCategory', auth, person.countLikesByCategory
app.get '/person/likes/byCategory', auth, person.likesByCategory

app.post '/person/links/histogram/count', auth, person.countLinksHistogram
app.get '/person/links/histogram', auth, person.getLinksHistogram

app.post '/person/logisticRegressionOnLinks', auth, person.logisticRegressionOnLinks

app.use express.static __dirname + '/public'

app.use express.errorHandler()


server = http.createServer(app)

require('./utils/socket-communicator').setup(server, sessionStore, cookieParser)

server.listen process.env.VMC_APP_PORT or 3000, ->
  console.log "Listening on #{server.address().address}:#{server.address().port}"
