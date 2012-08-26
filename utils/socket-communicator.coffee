
sio = null

exports.setup = (app, sessionStore, cookieParser) ->
  sio = require('socket.io').listen(app)

  parseCookie = (cookie, callback) ->
    fakeRequest =
      headers:
        cookie: cookie
    cookieParser(fakeRequest, null, (error) ->
      return callback(error) if error
      callback(null, fakeRequest.signedCookies)
    )

  sio.set 'authorization', (data, accept) ->
    if data.headers.cookie
      parseCookie data.headers.cookie, (error, cookies) ->
        return accept(error, false) if error

        data.sessionID = cookies['connect.sid']
        sessionStore.get data.sessionID, (err, session) ->
          if err
            return accept err, false
          if not session
            return accept(new Error('No session'), false)
          # save the session data and accept the connection
          data.session = session
          accept(null, true)
    else
      return accept(new Error('No cookie transmitted'), false)

  sio.sockets.on 'connection', (socket) ->
    # do all the session stuff
    socket.join socket.handshake.sessionID
    # socket.io will leave the room upon disconnect

exports.sendVolatile = (sessionID, event, data, callback) ->
  socket = sio.sockets.in(sessionID)
  if socket
    socket.volatile.emit(event, data)
    callback(null)
  else
    callback(new Error('No socket'))

exports.send = (sessionID, event, data, callback) ->
  socket = sio.sockets.in(sessionID)
  if socket
    socket.emit(event, data, callback)
  else
    callback(new Error('No socket'))
