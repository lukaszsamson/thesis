
exports.m = () ->
  likes = {}
  names = {}
  names[@facebookId] = @name
  @likes.forEach (l) =>
    share = {
    id: @facebookId
    friends: @friends.map (f) -> f.facebookId
    date: l.created_time
    }
    if not likes[l.name]
      likes[l.name] = []
    likes[l.name].push share
  @friends.forEach (f) =>
    names[f.facebookId] = f.name
    f.likes.forEach (l) =>
      share = {
      id: f.facebookId
      friends: [@facebookId].concat(f.mutualFriends.map (mf) -> mf.facebookId)
      date: l.created_time
      }
      if not likes[l.name]
        likes[l.name] = []
      likes[l.name].push share

  order = (a, b) ->
    if a.date > b.date
      return 1
    if b.date > a.date
      return -1
    return 0

  flows = {}
  for l, a of likes
    a.sort order
    for i in [0...a.length]
      for j in [(i + 1)...a.length]
        if a[i].friends.some((f) -> a[j].id == f)
          if not flows[a[i].id]
            flows[a[i].id] = {}
          if not flows[a[i].id][a[j].id]
            flows[a[i].id][a[j].id] = 0
          flows[a[i].id][a[j].id]++

  axis = []
  for i, v of flows
    if not axis.some((a) -> a.id == i)
      axis.push {
      id: i
      name: names[i]
      }
    for j, w of v
      if not axis.some((a) -> a.id == j)
        axis.push {
        id: j
        name: names[j]
        }
  cnt = 0
  result = []
  for i in [0...axis.length]
    result[i] = []
    for j in [0...axis.length]
      result[i][j] = if flows[axis[i].id] and flows[axis[i].id][axis[j].id] then flows[axis[i].id][axis[j].id] else 0
      cnt += result[i][j]


  emit(@facebookId, {
  matrix: result
  axis: axis
  cnt: cnt
  })

exports.r = (key, values) ->
  return values[0]