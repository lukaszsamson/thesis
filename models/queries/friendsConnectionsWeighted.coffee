
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

    value = 1
    @links.forEach((l) ->
      if f.links.some((l1) -> l1.link == l.link)
        value *= 1.05
    )
    @likes.forEach((l) ->
      if f.likes.some((l1) -> l1.name == l.name)
        value *= 1.05
    )
    connections.push {
    from: @facebookId
    to: f.facebookId
    value: value
    }
    connections.push {
    from: f.facebookId
    to: @facebookId
    value: value
    }
    f.mutualFriends.forEach (mf) =>
      if not connections.some((c) ->
        c.from == mf.facebookId and c.to == f.facebookId
      )
        f1 = @friends.filter((g) -> g.facebookId == mf.facebookId)[0]
        value = 1
        f.links.forEach((l) ->
          if f1.links.some((l1) -> l1.link == l.link)
            value *= 1.1
        )
        f.likes.forEach((l) ->
          if f1.likes.some((l1) -> l1.name == l.name)
            value *= 1.1
        )
        connections.push {
        from: mf.facebookId
        to: f.facebookId
        value: value
        }
        connections.push {
        from: f.facebookId
        to: mf.facebookId
        value: value
        }

  emit(@.facebookId, {
  people: people
  connections: connections
  })

exports.r = (key, values) ->
  return values[0]