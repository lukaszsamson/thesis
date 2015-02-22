express = require 'express'
http = require 'http'

mongoose = require('mongoose')
session = require('express-session')
RedisStore = require('connect-redis')(session)

db = mongoose.connect 'mongodb://localhost/test'

app = express()


app.set 'view engine', 'jade'
cookieParser =  require('cookie-parser')('shoop da woop')
app.use cookieParser
sessionStore = new RedisStore(
  #host: 'localhost'
  #port: ''
  ttl: 3600 # 1 hour
)
app.use session({
  cookie:
    path: '/'
    httpOnly: true
    maxAge: 3600000 # 1 hour
  store: sessionStore
})

#app.use express.logger()
app.use require('body-parser')()

oauthClient = require './utils/oauth-client'
auth = oauthClient.authenticate
  appId: '102219526568766'
  appSecret: 'ee755ea1ef4ab900bb46b497d5a93ca0'
  scope: 'read_stream,user_likes,friends_likes'

main = require './controllers/main'
app.get '/', oauthClient.redirector('/person'), main.index
app.post '/logOut', oauthClient.logOut

person = require './controllers/person'
friends = require './controllers/friends'
links = require './controllers/links'
likes = require './controllers/likes'

app.all '/person*', auth

app.get '/person', person.index
app.post '/person/getData', person.getData

app.get '/person/friends', friends.index
app.get '/person/friends/connections', friends.connections
app.get '/person/friends/connectionsWeighted', friends.connectionsWeighted

app.get '/person/links', links.index
app.get '/person/links/flow', links.flow
app.get '/person/links/histogram', links.histogram
app.get '/person/links/logisticRegression', links.logisticRegression


app.get '/person/likes', likes.index
app.get '/person/likes/cloud', likes.cloud
app.get '/person/likes/histogram', likes.histogram
app.get '/person/likes/flow', likes.flow


mapreduce = require './controllers/mapreduce'
app.all  '/person/mapReduce/*', mapreduce.validateMapReduceOperation
app.post '/person/mapReduce/:operation/request', mapreduce.mapReduce
app.get  '/person/mapReduce/:operation/results', mapreduce.mapReduceResults


app.use express.static __dirname + '/public'

app.use require('errorhandler')()


server = http.createServer(app)

require('./utils/socket-communicator').setup(server, sessionStore, cookieParser)

server.listen process.env.VMC_APP_PORT or 3000, ->
  console.log "Listening on #{server.address().address}:#{server.address().port}"
