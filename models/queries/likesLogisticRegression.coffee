
exports.m = () ->
  result = {}
  result[@facebookId] = {
  likes: @likes.map (l) -> l.name
  friends: @friends.map (f) ->  f.facebookId
  user: true
  }
  cnt = 0
  for f in @friends
    #if f.mutualFriends.length < 8
    #  continue
    #if ++cnt > 10
    #  break
    result[f.facebookId] = {
    likes: f.likes.map (l) -> l.name
    friends: f.mutualFriends.map((mf) -> mf.facebookId).concat(@facebookId)
    user: false
    }
  emit(@facebookId, result)

exports.r = (key, values) ->
  result = {}
  values.forEach (val) ->
    for k, v of val
      if result[k]
        if not result[k].user and v.user
          result[k] = v
      else
        result[k] = v

  return result

exports.f = (key, ffff) ->
  getLikes = (friends) ->
    likes = {}
    for k, v of friends
      v.likes.forEach (l) ->
        if likes[l]
          likes[l]++
        else
          likes[l] = 1
    res = []
    for l, t of likes
      res.push(l) if t > 6
    return res

  getFriends = (friends, likes) ->
    res = {}
    for k, v of friends
      if likes.some((lc) -> v.likes.indexOf(lc) != -1)
        res[k] = {
        likes: v.likes.filter (l) -> likes.indexOf(l) != -1
        }
    for k, v of res
      v.friends = friends[k].friends.filter (f) -> res[f]

    return res

  likes = getLikes(ffff)
  value = getFriends(ffff, likes)


  getScore = (i, j) ->
    score = 0
    for k in [0...likes.length]
      if value[i].likes.indexOf(likes[k]) != -1
        score += w[k]
      if value[j].likes.indexOf(likes[k]) != -1
        score += w[k]

    return score

  updateWeights = (i, j, update) ->
    for k in [0...likes.length]
      if value[i].likes.indexOf(likes[k]) != -1
        w[k] += update
      if value[j].likes.indexOf(likes[k]) != -1
        w[k] += update


  w = new Array(likes.length)
  for i in [0...w.length]
    w[i] = 0
  delta = 0.002
  res = []
  for q in [0...1000]
    c1 = -1
    for i, t of value
      c2 = -1
      c1++
      for j, y of value
        c2++
        if c2 > c1
          p = 1 / (1 + Math.exp(-getScore(i, j)))
          friends = t.friends.indexOf(j) != -1
          update = (friends - p) * delta
          updateWeights(i, j, update)

    error = 0
    tried = 0
    fp = 0
    fn = 0
    res[q] = {}
    for i, t of value
      for j, y of value
        if i != j
          tried++
          p = 1 / (1 + Math.exp(-getScore(i, j)))
          friends = t.friends.indexOf(j) != -1
          e = (friends - p)
          error += e * e
          score = p > 0.5
          if friends != score
            if friends and not score
              fn++
            if not friends and score
              fp++
    res[q].error = error
    print "#{q}: e #{error} fp #{fp} fn #{fn} a #{tried}"

  return {
  coeffs: w
  err: res
  }

f1: (key, value) ->
  getLinks = (value) ->
    len = 20
    links = []
    for k, v of value
      v.links.forEach (l) ->
        if links.indexOf(l) == -1
          links.push(l)
    result = new Array(len)
    for i in [0..links.length - 1]
      h = i % len
      if not result[h]
        result[h] = []
      result[h].push links[i]
    return result

  getScore = (i, j) ->
    score = 0
    for k in [0..links.length - 1]
      if links[k].some((lc) -> value[i].links.indexOf(lc) != -1)
        score += w[k]
      if links[k].some((lc) -> value[j].links.indexOf(lc) != -1)
        score += w[links.length + k]

    return score

  updateWeights = (i, j, update) ->
    for k in [0..links.length - 1]
      if links[k].some((lc) -> value[i].links.indexOf(lc) != -1)
        w[k] += update
      if links[k].some((lc) -> value[j].links.indexOf(lc) != -1)
        w[links.length + k] += update

  links = getLinks(value)

  w = new Array(links.length * 2)
  for i in [0..w.length - 1]
    w[i] = 0
  delta = 0.002
  res = []
  for q in [0..20]
    for i, t of value
      for j, y of value
        if i != j
          p = 1 / (1 + Math.exp(-getScore(i, j)))
          friends = t.friends.indexOf(j) != -1
          update = (friends - p) * delta
          updateWeights(i, j, update)

    error = 0
    res[q] = {}
    for i, t of value
      for j, y of value
        if i != j
          p = 1 / (1 + Math.exp(-getScore(i, j)))
          friends = t.friends.indexOf(j) != -1
          e = (friends - p)
          error += e * e
    res[q].error = error
    print error

  return {
    coeffs: w
    err: res
  }

