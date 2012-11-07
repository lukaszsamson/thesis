var redis = require('redis')

var client = redis.createClient()
var client1 = redis.createClient()

function complete(id, cb) {
    //console.log('complete called')
    client.multi()
        .get('task:' + id + ':parent')
        .llen('task:' + id + ':childrenToProcess')
        .exec(function (e, r1) {
            if (e) return cb(e)
            if (!r1) return cb(new Error('Optimistic concurrency'))
            var childrenLength = r1[1]
            var parentId = r1[0]
            //console.log('children len: ' + childrenLength + ' parent: ' + parentId)
            if (childrenLength != 0) {
                //console.log('parent completed, ' + childrenLength + ' child(ren) pending')
                return client.set('task:' + id + ':state', 'waitingForChildren', cb)
            }
            var multi = client.multi()
                .set('task:' + id + ':state', 'completed')
                .lrem('active', 1, id)
            if (parentId) {
                //console.log('removing child from parent')
                multi.lrem('task:' + parentId + ":childrenToProcess", 1, id)
                multi.llen('task:' + parentId + ":childrenToProcess")
                multi.get('task:' + parentId + ":state")
            }
            multi.exec(function (e, r) {
                //console.log('uuu')
                if (e) return cb(e)
                if (!r) return cb(new Error('Optimistic concurrency'))
                //console.log(r)
                client.publish("taskComplete", id)
                if (parentId && r[3] == 0 && r[4] == 'waitingForChildren') {
                    //console.log('calling complete for parent')
                    complete(parentId, cb)
                } else {
                    cb()
                }
            })


        });
}


function fail(id, cb) {
    //console.log('fail called')
    client.multi()
        .set('task:' + id + ':state', 'requested')
        .lrem('active', 1, id)
        .rpush('tasks', id)
        .exec(function (e, r) {
            if (e) return cb(e)
            if (!r) return cb(new Error('Optimistic concurrency'))
            client.publish('taskCrations', id)
            cb(null)
        })
}


var lock = false;
function doWork() {
    //console.log('do work', lock)
    if (lock) return
    lock = true
    work(function (end) {
        //console.log('work cb', end)
        lock = false
        if (!end)
            setTimeout(doWork, 0)
    })
}

function work(cb) {
    //console.log('l')
    client.watch('tasks', function (e) {
        if (e) {
            console.log(e)
            return cb()
        }
        client.lindex('tasks', -1, function (e, id) {
            if (e) {
                console.log(e)
                return cb()
            }
            if (!id) {
                //console.log('No tasks in queue')
                return client.unwatch(function (e) {
                    if (e) {
                        console.log(e)
                        cb(true)
                    }
                    cb(true)
                })
            }
            //console.log('lindex returned ', id)
            client.multi()
                .rpop('tasks')
                .rpush('active', id)
                .exec(function (e, r) {
                    if (e) {
                        console.log(e)
                        return cb()
                    }
                    if (!r) {
                        console.log(new Error('Optimistic concurrency'))
                        return cb()
                    }
                    //console.log('calling process')

                    process(id, function (e) {
                        if (e) {
                            console.log(e)
                            return cb()
                        }
                        return cb()
                    })
                })
        })
    })
}

function process(id, cb) {
    //console.log('process called for ', id)
    client.multi()
        .get("task:" + id)
        .get("task:" + id + ":data")
        .exec(function (e, r) {
            if (e) return cb(e)
            if (!r) return cb(new Error('Optimistic concurrency'))

            var type = r[0]
            if (!type) return cb(new Error('Type not found'))

            try {
                var data = JSON.parse(r[1])
            } catch (e) {
                return cb(e)
            }
            function callback(e) {
                if (e) {
                    console.log(e)
                    return fail(id, function () {
                    })
                }
                complete(id, function () {
                })
            }

            try {
                if (handlers['process'][type])
                    handlers['process'][type](id, data, callback)
                else
                    callback(null)
            } catch (e) {
                return callback(e)
            }
            cb()
        })
}

var handlers = {}

function on(action, type, cb) {
    if (!handlers[action])
        handlers[action] = {}
    handlers[action][type] = cb
}

function start() {
    client1.on('message', function (channel, message) {
        //console.log('message recieved', channel, message)
        if (channel == 'taskCrations') {

            doWork()
        } else if (channel == 'taskComplete') {
            var id = message
            client.multi()
                .get('task:' + id)
                .get('task:' + id + ':data')
                .exec(function(e, r) {
                    if (e) console.log(e)
                    if (!r) console.log(new Error('Optimistic concurrency'))
                    var data = JSON.parse(r[1])
                    handlers['complete'][r[0]](id, data)
                })
        }
    })
    client1.subscribe('taskCrations')
    client1.subscribe('taskComplete')
    doWork()
}

function stop() {
    client1.quit()
}

function createTask(type, data, cb) {
    try {
        var serializedData = JSON.stringify(data)
    } catch (e) {
        return cb(e)
    }
    client.incr('ids', function (e, id) {
        if (e) return cb(e)
        //console.log('id: ' + id)
        client.multi()
            .rpush('tasks', id)
            .set('task:' + id, type)
            .set('task:' + id + ':data', serializedData)
            .set('task:' + id + ':state', 'requested')
            .exec(function (e, r) {
                if (e) return cb(e)
                //console.log("created, r: " + r)
                client.publish('taskCrations', id)
                return cb(null, id)
            })
    })
}

function createChildTask(parentId, type, data, cb) {
    try {
        var serializedData = JSON.stringify(data)
    } catch (e) {
        return cb(e)
    }
    client.incr('ids', function (e, id) {
        if (e) return cb(e)
        //console.log('id: ' + id)
        client.multi()
            .rpush('tasks', id)
            .set('task:' + id, type)
            .set('task:' + id + ':data', serializedData)
            .set('task:' + id + ':state', 'requested')
            .set('task:' + id + ':parent', parentId)
            .hset('task:' + parentId + ":childrenState", id, 'requested')
            .rpush('task:' + parentId + ":childrenToProcess", id)
            .exec(function (e, r) {
                if (e) return cb(e)
                if (!r) throw new Error('optimistic concurrency')
                //console.log("created, r: " + r)
                client.publish('taskCrations', id)
                return cb(null, id)
            })
    })
}

module.exports.start = start
module.exports.stop = stop
module.exports.on = on
module.exports.createChildTask = createChildTask
module.exports.createTask = createTask
exports = module.exports

