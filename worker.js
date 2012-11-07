var redis = require('redis')

var workerClient = redis.createClient()
var client = redis.createClient()
var client1 = redis.createClient()

function complete(id, cb) {
    //console.log('complete called')
    client.multi()
        .get('task:' + id + ':parent')
        .llen('task:' + id + ':childrenToProcess')
        .llen('task:' + id + ':childrenFailed')
        .get('task:' + id)
        .exec(function (e, r1) {
            if (e) return cb(e)
            if (!r1) return cb(new Error('Optimistic concurrency'))
            var childrenLength = r1[1]
            var parentId = r1[0]
            var type = r1[3]
            if (r1[2] > 0) {
                cb()
            }
            //console.log('children len: ' + childrenLength + ' parent: ' + parentId)
            if (childrenLength != 0) {
                console.log('parent completed, ' + childrenLength + ' child(ren) pending')
                return client.multi()
                    .set('task:' + id + ':state', 'waitingForChildren')
                    .exec(cb)
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
            multi.decr('processed:' + type)
                .set('task:' + id + ':completed', Date.now())
            multi.exec(function (e, r) {
                console.log('uuu')
                if (e) return cb(e)
                if (!r) return cb(new Error('Optimistic concurrency'))
                //console.log(r)
                client.publish("taskComplete", id)
                if (parentId && r[3] == 0 && r[4] == 'waitingForChildren') {
                    console.log('calling complete for parent')
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
        .set('task:' + id + ':state', 'failed')
        .incr('task:' + id + ':failures')
        .get('task:' + id + ':maxFailures')
        .get('task:' + id + ':parent')
        .get('task:' + id)
        .set('task:' + id + ':failed', Date.now())
        .exec(function (e, r) {
            if (e) return cb(e)
            if (!r) return cb(new Error('Optimistic concurrency'))
            console.log(r)
            var type = r[4]
            if (r[2] == 0 || r[1] < r[2]) {
                client.multi()
                    .set('task:' + id + ':state', 'requested')
                    .lrem('active', 1, id)
                    .lpush('tasks', id)
                    .decr('processed:' + type)
                    .exec(function (e, r) {
                        if (e) return cb(e)
                        if (!r) return cb(new Error('Optimistic concurrency'))
                        client.publish('taskCrations', id)
                        cb()
                    })
            } else {


                client.publish('taskFailed', id)
                if (r[3]) {
                    console.log('child failed')
                    client.multi()
                        .lrem('active', 1, id)
                        .decr('processed:' + type)
                        .rpush('task:' + r[3] + ':childrenFailed', id)
                        .exec(function (e, r1) {
                            if (e) return cb(e)
                            if (!r1) return cb(new Error('Optimistic concurrency'))
                            fail(r[3], cb)
                        })
                } else {
                    client.multi()
                        .lrem('active', 1, id)
                        .decr('processed:' + type)
                        .exec(function (e, r1) {
                            if (e) return cb(e)
                            if (!r) return cb(new Error('Optimistic concurrency'))
                            cb()
                        })
                }
            }
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
    //console.log('waiting')
    workerClient.brpoplpush('tasks', 'active', 500, function (e, id) {
        //console.log('cb')
        if (e) {
            console.log(e)
            return cb()
        }
        if (id == null) {
            console.log("spin")
            return cb()
        }
        process(id, function (e) {
            if (e) {
                console.log(e)
                return cb()
            }
            return cb()
        })
    })

}

function delay(id, type, cb) {
    client.multi()
        .lrem('active', 1, id)
        .lpush('tasks', id)
        .decr('processed:' + type)
        .exec(function (e, r) {
            if (e) return cb(e)
            if (!r) return cb(new Error('Optimistic concurrency'))
            cb()
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

            client.multi()
                .incr('processed:' + type)
                .get('maxProcessed:' + type)
                .exec(function (e, r1) {
                    if (e) return cb(e)
                    if (!r1) return cb(new Error('Optimistic concurrency'))
                    if (r1[1] != 0 && r1[0] > r1[1]) {
                        console.log(r1, r1[0] != 0)
                        delay(id, type, cb)
                    } else {
                        console.log('no delay')
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
                    }
                })


        })
}

var handlers = {}

function on(action, type, options, cb) {
    var def = {
        maxProcessed:0
    }
    if (typeof(options) == 'function') {
        cb = options
        options = def
    }
    for (var o in def) {
        if (!options[o])
            options[o] = def[o]
    }
    if (action == 'process') {
        client.set('maxProcessed:' + type, options.maxProcessed)
    }

    if (!handlers[action])
        handlers[action] = {}
    handlers[action][type] = cb
}

function start() {
    client1.on('message', function (channel, message) {
        console.log('message recieved', channel, message)
        if (channel == 'taskCrations') {

            doWork()
        } else if (channel == 'taskComplete') {
            var id = message
            client.multi()
                .get('task:' + id)
                .get('task:' + id + ':data')
                .exec(function (e, r) {
                    if (e) console.log(e)
                    if (!r) console.log(new Error('Optimistic concurrency'))
                    var data = JSON.parse(r[1])
                    handlers['complete'][r[0]](id, data)
                })
        }
    })
    client1.subscribe('taskCrations')
    client1.subscribe('taskComplete')
    client1.subscribe('taskFailed')
    doWork()
}

function stop() {
    client1.quit()
}

defaultOptions = {
    maxFailures:0,
    delay:0,
    delayAfterFailure:0
}

function createTask(type, data, options, cb) {
    if (typeof(options) == 'function') {
        cb = options
        options = defaultOptions
    }
    for (var o in defaultOptions) {
        if (!options[o])
            options[o] = defaultOptions[o]
    }
    try {
        var serializedData = JSON.stringify(data)
    } catch (e) {
        return cb(e)
    }
    client.incr('ids', function (e, id) {
        if (e) return cb(e)
        //console.log('id: ' + id)
        var multi = client.multi()
            .lpush('tasks', id)
            .set('task:' + id, type)
            .set('task:' + id + ':data', serializedData)
            .set('task:' + id + ':created', Date.now())
            .set('task:' + id + ':state', 'requested')

        for (var o in options)
            multi.set('task:' + id + ':' + o, options[o])

        multi.exec(function (e, r) {
                if (e) return cb(e)
                //console.log("created, r: " + r)
                client.publish('taskCrations', id)
                return cb(null, id)
            })
    })
}

function createChildTask(parentId, type, data, options, cb) {
    if (typeof(options) == 'function') {
        cb = options
        options = defaultOptions
    }
    for (var o in defaultOptions) {
        if (!options[o])
            options[o] = defaultOptions[o]
    }
    try {
        var serializedData = JSON.stringify(data)
    } catch (e) {
        return cb(e)
    }
    client.incr('ids', function (e, id) {
        if (e) return cb(e)
        //console.log('id: ' + id)
        var multi = client.multi()
            .lpush('tasks', id)
            .set('task:' + id, type)
            .set('task:' + id + ':maxFailures', options.maxFailures)
            .set('task:' + id + ':data', serializedData)
            .set('task:' + id + ':state', 'requested')
            .set('task:' + id + ':created', Date.now())
            .set('task:' + id + ':parent', parentId)
            .hset('task:' + parentId + ":childrenState", id, 'requested')
            .rpush('task:' + parentId + ":childrenToProcess", id)

        for (var o in options)
            multi.set('task:' + id + ':' + o, options[o])

        multi.exec(function (e, r) {
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

