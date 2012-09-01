friendsConnections = {}
friendsConnections.m = () ->
  emit(@facebookId, {
  user: true
  friends: @friends.map (friend) -> friend.facebookId
  })
  @friends.forEach((friend) =>
    emit(friend.facebookId, {
    user: false
    friends: friend.mutualFriends.map((mf) -> mf.facebookId).concat(@facebookId)
    })
  )

friendsConnections.r = (key, values) ->
  fr = []
  count = 0
  values.forEach (value) ->
    value.friends.forEach (friend) ->
      fr.push friend if fr.indexOf friend < 0
  return {
  friends: fr
  }
