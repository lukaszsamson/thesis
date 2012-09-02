
exports.m = () ->
  people = [{
  name: @name
  id: @facebookId
  user: true
  }]
  connections = []
  @friends.forEach (f) =>
    people.push {
    name: f.name
    id: f.facebookId
    user: false
    }
    connections.push {
    from: @facebookId
    to: f.facebookId
    }
    connections.push {
    from: f.facebookId
    to: @facebookId
    }
    f.mutualFriends.forEach (mf) ->
      if not connections.some((c) ->
        c.from == mf.facebookId and c.to == f.facebookId
      )
        connections.push {
        from: mf.facebookId
        to: f.facebookId
        }
        connections.push {
        from: f.facebookId
        to: mf.facebookId
        }

  emit(@.facebookId, {
  people: people
  connections: connections
  })

exports.r = (key, values) ->
  return values[0]