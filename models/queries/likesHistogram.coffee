exports.m = () ->
  @likes.forEach (l) =>
    r = {}
    r[l.name] = [@facebookId]
    emit(@facebookId, r)
  @friends.forEach (f) =>
    f.likes.forEach (l) =>
      r = {}
      r[l.name] = [f.facebookId]
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
    name: l
    likes: ids.length
    }
  result.sort (a, b) ->
    if a.likes > b.likes
      return 1
    if b.likes > a.likes
      return -1
    return 0
  return result
  