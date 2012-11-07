var redis = require('redis')
var client = redis.createClient()

function createTask(type, data, cb) {
    try {
        var serializedData = JSON.stringify(data)
    } catch(e) {
        return cb(e)
    }
    var id = Date.now()
    console.log('id: ' + id)
    client.multi()
        .rpush('tasks', id)
        .set('task:' + id, type)
        .set('task:' + id + ':data', serializedData)
        .set('task:' + id + ':state', 'requested')
        .exec(function(e, r) {
            if (e) return cb(e)
            console.log("created, r: " + r)
            client.publish('taskCrations', id)
            return cb(null, id)
        })
}

function createChildTask(parentId, type, data, cb) {
    try {
        var serializedData = JSON.stringify(data)
    } catch(e) {
        return cb(e)
    }
    var id = Date.now()
    console.log('id: ' + id)
    client.multi()
        .rpush('tasks', id)
        .set('task:' + id, type)
        .set('task:' + id + ':data', serializedData)
        .set('task:' + id + ':state', 'requested')
        .set('task:' + id + ':parent', parentId)
        .hset('task:' + parentId + ":childrenState", id, 'requested')
        .rpush('task:' + parentId + ":childrenToProcess", id)
        .exec(function(e, r) {
            if (e) return cb(e)
            if (!r) throw new Error('optimistic concurrency')
            console.log("created, r: " + r)
            client.publish('taskCrations', id)
            return cb(null, id)
        })
}

var actions = {}

function on(type, cb) {
    actions[type] = cb
}

module.exports.createTask = createTask
module.exports.on = on
exports = module.exports