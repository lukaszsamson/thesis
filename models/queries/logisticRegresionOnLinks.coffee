logisticRegressionOnLinks = {
m: () ->
  result = {}
  result[@facebookId] = {
  links: @links.map (l) -> l.link
  friends: @friends.map (f) ->  f.facebookId
  user: true
  }
  cnt = 0
  for f in @friends
    if f.mutualFriends.length < 8
      continue
    #if ++cnt > 10
    #  break
    result[f.facebookId] = {
    links: f.links.map (l) -> l.link
    friends: f.mutualFriends.map((mf) -> mf.facebookId).concat(@facebookId)
    user: false
    }
  emit(1, result)

r: (key, values) ->
  result = {}
  values.forEach (v) ->
    for key, val of v
      if result[key]
        if not result[key].user and val.user
          result[key] = val
      else
        result[key] = val

  return result

f: (key, ffff) ->
  getLinks = (friends) ->
    links = {}
    for k, v of friends
      v.links.forEach (l) ->
        if links[l]
          links[l]++
        else
          links[l] = 1
    res = []
    for l, t of links
      res.push(l) if t > 1
    return res

  getFriends = (friends, links) ->
    res = {}
    for k, v of friends
      #if links.some((lc) -> v.links.indexOf(lc) != -1)
      res[k] = {
      links: v.links.filter (l) -> links.indexOf(l) != -1
      }
    for k, v of res
      v.friends = friends[k].friends.filter (f) -> res[f]

    return res

  links = getLinks(ffff)
  value = getFriends(ffff, links)


  getScore = (i, j) ->
    score = 0
    for k in [0...links.length]
      if value[i].links.indexOf(links[k]) != -1
        score += w[k]
      if value[j].links.indexOf(links[k]) != -1
        score += w[k]

    return score

  updateWeights = (i, j, update) ->
    for k in [0...links.length]
      if value[i].links.indexOf(links[k]) != -1
        w[k] += update
      if value[j].links.indexOf(links[k]) != -1
        w[k] += update


  w = new Array(links.length)
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
          friends = t.friends.indexOf(j) != -1
          score = getScore(i, j) >= 0.5
          #res[q]["#{i} #{j}"] = {
          #score: score
          #friends: friends
          #}
          if friends != score
            error++
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
          friends = t.friends.indexOf(j) != -1
          score = getScore(i, j) >= 0
          res[q]["#{i} #{j}"] = {
          score: score
          friends: friends
          }
          if friends != score
            error++
    res[q].error = error

  return {
  coeffs: w
  err: res
  }
}
