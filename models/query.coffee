reduceNoop = (key, values) ->
  return values[0]

operations = {}

operations.findConnections = findConnections = {}
findConnections.m = () ->
  people = [{
  name: @name
  id: @facebookId
  }]
  connections = []
  @friends.forEach (f) =>
    people.push {
    name: f.name
    id: f.facebookId
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

findConnections.r = reduceNoop

operations.findLinkFlows = findLinkFlows = {}
findLinkFlows.m = () ->
  links = {}
  @links.forEach (l) =>
    share = {
    id: @facebookId
    friends: @friends.map (f) -> f.facebookId
    date: l.create_date
    }
    if not links[l.link]
      links[l.link] = []
    links[l.link].push share
  @friends.forEach (f) =>
    f.links.forEach (l) =>
      share = {
      id: f.facebookId
      friends: [@facebookId].concat(f.mutualFriends.map (mf) -> mf.facebookId)
      date: l.create_date
      }
      if not links[l.link]
        links[l.link] = []
      links[l.link].push share

  order = (a, b) ->
    if a.date < b.date
      return 1
    if b.date < a.date
      return -1
    return 0

  flows = {}
  for l, a of links
    a.sort order
    for i in [0...a.length]
      for j in [(i + 1)...a.length]
        if a[i].friends.some((f) -> a[j].id == f)
          if not flows[a[i].id]
            flows[a[i].id] = {}
          if not flows[a[i].id][a[j].id]
            flows[a[i].id][a[j].id] = 0
          flows[a[i].id][a[j].id]++
  emit(@facebookId, flows)

findLinkFlows.r = reduceNoop

exports.validate = (operation) ->
  return operations[operation]

for o, t of operations
  exports[o] = t
