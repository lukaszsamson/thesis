reduceNoop = (key, values) ->
  return values[0]

operations = {
  friendsConnections: require('./queries/friendsConnections')
  friendsConnectionsWeighted: require('./queries/friendsConnectionsWeighted')
  linksFlow: require('./queries/linksFlow')
  likesFlow: require('./queries/likesFlow')
  linksHistogram: require('./queries/linksHistogram')
  likesHistogram: require('./queries/likesHistogram')
  linksLogisticRegression: require('./queries/linksLogisticRegression')
  likesLogisticRegression: require('./queries/likesLogisticRegression')
}





exports.validate = (operation) ->
  return operations[operation]

for o, t of operations
  exports[o] = t
