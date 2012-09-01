
exports.m = () ->
  @links.forEach (l) =>
    r = {}
    r[l.link] = [@facebookId]
    emit(@facebookId, r)
  @friends.forEach (f) =>
    f.links.forEach (l) =>
      r = {}
      r[l.link] = [f.facebookId]
      emit(@facebookId, r)

exports.r = (key, values) ->
  result = {}
  values.forEach (v) ->
    for l, ids of v
      if result[l]
        result[l] = result[l].concat ids
      else
        result[l] = ids
  return result

exports.f = (key, value) ->
  result = []
  for l, ids of value
    result.push {
    link: l
    shares: ids.length
    }
  result.sort (a, b) ->
    if a.shares > b.shares
      return 1
    if b.shares > a.shares
      return -1
    return 0
  return result
