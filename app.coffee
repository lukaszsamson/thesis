express = require 'express'
stylus = require 'stylus'
assets = require 'connect-assets'

mongoose = require('mongoose')

db = mongoose.connect 'mongodb://localhost/test'

app = express()
app.use assets()
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

test = require './controllers/test'
app.get '/test/', test.index

person = require './controllers/person'
app.get '/person', person.index
app.get '/person/startCountLinks', person.countLinks
app.get '/person/countLinks', person.getCountLinks
app.use express.static __dirname + '/public'
app.use express.errorHandler
  dumpExceptions: true
  showStack: true

app.listen process.env.VMC_APP_PORT or 3000, ->
  console.log 'Listening...'