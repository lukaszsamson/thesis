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

app.all '/person*', auth

app.get '/person', person.index

app.get '/person/friends', person.friends
app.get '/person/links/chord', person.linksChord

app.post '/person/getData', person.getData
app.post '/person/countLinks', person.countLinks
app.get '/person/links', person.links
app.post '/person/countLikes/byName', person.countLikesByName
app.get '/person/likes/byName', person.likesByName
app.post '/person/countLikes/byCategory', person.countLikesByCategory
app.get '/person/likes/byCategory', person.likesByCategory

app.post '/person/links/histogram/count', person.countLinksHistogram
app.get '/person/links/histogram', person.getLinksHistogram

app.all  '/person/mapReduce/*', person.validateMapReduceOperation
app.post '/person/mapReduce/:operation/request', person.mapReduce
app.get  '/person/mapReduce/:operation/results', person.mapReduceResults

app.post '/person/logisticRegressionOnLinks', person.logisticRegressionOnLinks

app.use express.static __dirname + '/public'

app.use express.errorHandler()


server = http.createServer(app)

require('./utils/socket-communicator').setup(server, sessionStore, cookieParser)

server.listen process.env.VMC_APP_PORT or 3000, ->
  console.log "Listening on #{server.address().address}:#{server.address().port}"
