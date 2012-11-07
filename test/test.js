var assert = require('assert')

var worker = require('../worker')
var redis = require('redis')

var client = redis.createClient()
worker.start()

describe('tasks', function () {
//    beforeEach(function (done) {
//        worker.start()
//        done()
//    })
//    afterEach(function (done) {
//        worker.stop()
//        done()
//    })


//    describe('worker', function () {
//        it('should work', function (cb) {
//            setTimeout(cb, 1000)
//        })
//    })

    afterEach(function (done) {
        client.llen('active', function(e, l) {
            if (e) return done(e)
            if (l > 0) return done(new Error('active leak'))
            done()
        })
    })

    describe('single task', function () {
        it('should handle immediate tasks', function (done) {
            var complete = false
            worker.on('process', 't1', function (id, data, cb) {
                complete = true
                cb()
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                done()
            })
            worker.createTask('t1', {}, function () {
            })
        })

        it('should handle long tasks', function (done) {
            var complete = false
            worker.on('process', 't1', function (id, data, cb) {
                setTimeout(function () {
                    complete = true
                    cb()
                }, 100)
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                done()
            })
            worker.createTask('t1', {}, function () {
            })
        })
    })

    describe('failing task', function () {
        it('should complete when failures less than max failures', function (done) {
            var i = 0
            var complete = false
            var completeCalled = false
            worker.on('process', 't1', function (id, data, cb) {
                if (++i < 3) {
                    cb(new Error('ups'))
                } else {
                    complete = true
                    cb()
                }
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                completeCalled = true
            })
            worker.createTask('t1', {}, {maxFailures:5}, function () {
            })
            setTimeout(function () {
                assert(completeCalled)
                done()
            }, 500)
        })
        it('should fail after max failures', function (done) {
            var i = 0
            var complete = false
            worker.on('process', 't1', function (id, data, cb) {
                if (++i < 5) {
                    cb(new Error('ups'))
                } else {
                    complete = true
                    cb()
                }
            })
            worker.on('complete', 't1', function () {
                assert(false)

            })
            worker.createTask('t1', {}, {maxFailures:3}, function () {
            })
            setTimeout(done, 500)
        })

        it('should handle immediate failing tasks', function (done) {
            var i = 0
            var complete = false
            worker.on('process', 't1', function (id, data, cb) {
                if (++i < 3) {
                    cb(new Error('ups'))
                } else {
                    complete = true
                    cb()
                }
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                done()
            })
            worker.createTask('t1', {}, function () {
            })
        })

        it('should handle long failing tasks', function (done) {
            var i = 0
            var complete = false
            worker.on('process', 't1', function (id, data, cb) {
                setTimeout(function () {
                    if (++i < 3) {
                        cb(new Error('ups'))
                    } else {
                        complete = true
                        cb()
                    }
                }, 100)
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                done()
            })
            worker.createTask('t1', {}, function () {
            })
        })


//        it('should go to the end of the queue', function (done) {
//            var i = 0
//            var complete1 = false
//            var complete2 = false
//            var complete1Called = false
//            var complete2Called = false
//            worker.on('process', 't1', function (id, data, cb) {
//                setTimeout(function () {
//                    if (++i < 2) {
//                        cb(new Error('ups'))
//                    } else {
//                        complete1 = true
//                        cb()
//                    }
//                }, 100)
//            })
//            worker.on('process', 't2', function (id, data, cb) {
//                setTimeout(function () {
//                    complete2 = true
//                    cb()
//                }, 200)
//            })
//            worker.on('complete', 't1', function () {
//                assert(complete1)
//                complete1Called = true
//            })
//            worker.on('complete', 't2', function () {
//                assert(complete2)
//                complete2Called = true
//            })
//            worker.createTask('t1', {}, function () {
//            })
//            setTimeout(function () {
//                worker.createTask('t2', {}, function () {
//                })
//            }, 50)
//        })
    })

    describe('concurrency', function () {
        it('should be limited', function (done) {
            var complete = false
            var processed = 0
            var max = 3
            worker.on('process', 't1', {maxProcessed: max}, function (id, data, cb) {
                assert(++processed <= max)
                setTimeout(function () {
                    complete = true
                    --processed
                    cb()
                }, 20)
            })
            worker.on('complete', 't1', function () {
                assert(complete)
            })
            for(var i = 0; i < 10; i++)
                worker.createTask('t1', {}, function () {
                })
            setTimeout(done, 500)
        })
    })


    describe('multiple task', function () {
        it('should handle immediate tasks', function (done) {
            var complete = false
            var childComplete = false
            var completeCalled = false
            var childCompleteCalled = false
            worker.on('process', 't1', function (id, data, cb) {
                //console.log('process t1')
                complete = true
                worker.createChildTask(id, 't2', {}, cb)
            })
            worker.on('process', 't2', function (id, data, cb) {
                //console.log('process t2')
                childComplete = true
                cb()
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                completeCalled = true
                assert(childComplete)
                assert(childCompleteCalled)

            })
            worker.on('complete', 't2', function () {
                assert(childComplete)
                childCompleteCalled = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                assert(childCompleteCalled)
                assert(completeCalled)
                done()
            }, 100)
        })

        it('should handle slow children', function (done) {
            var complete = false
            var childComplete = false
            var completeCalled = false
            var childCompleteCalled = false
            worker.on('process', 't1', function (id, data, cb) {
                //console.log('process t1')
                complete = true
                worker.createChildTask(id, 't2', {}, cb)
            })
            worker.on('process', 't2', function (id, data, cb) {
                //console.log('process t2')
                setTimeout(function () {
                    childComplete = true
                    cb()
                }, 100)
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                completeCalled = true
                assert(childComplete)
                assert(childCompleteCalled)

            })
            worker.on('complete', 't2', function () {
                assert(childComplete)
                childCompleteCalled = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                assert(childCompleteCalled)
                assert(completeCalled)
                done()
            }, 300)
        })

        it('should handle slow parent', function (done) {
            var complete = false
            var childComplete = false
            var completeCalled = false
            var childCompleteCalled = false
            worker.on('process', 't1', function (id, data, cb) {
                //console.log('process t1')
                worker.createChildTask(id, 't2', {}, function () {
                })
                setTimeout(function () {
                    complete = true
                    cb()
                }, 100)
            })
            worker.on('process', 't2', function (id, data, cb) {
                //console.log('process t2')

                childComplete = true
                cb()

            })
            worker.on('complete', 't1', function () {
                assert(complete)
                completeCalled = true
                assert(childComplete)
                assert(childCompleteCalled)

            })
            worker.on('complete', 't2', function () {
                assert(childComplete)
                childCompleteCalled = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                assert(childCompleteCalled)
                assert(completeCalled)
                done()
            }, 300)
        })

        it('should handle multiple children', function (done) {
            var cnt = 30
            var complete = false
            var childComplete = []
            var completeCalled = false
            var childCompleteCalled = []
            for (var i = 0; i < cnt; i++) {
                childComplete[i] = false
                childCompleteCalled[i] = false
            }
            worker.on('process', 't1', function (id, data, cb) {
                //console.log('process t1')
                for (var i = 0; i < cnt; i++) {
                    (function () {
                        var r = i
                        worker.createChildTask(id, 't2', {t:10 + i * 9, i:r}, function () {
                        })
                    })()
                }
                setTimeout(function () {
                    complete = true
                    cb()
                }, 50)
            })
            worker.on('process', 't2', function (id, data, cb) {
                //console.log('process t2')
                setTimeout(function () {
                    childComplete[data.i] = true
                    cb()
                }, data.t)

            })
            worker.on('complete', 't1', function () {
                assert(complete)
                completeCalled = true
                for (var i = 0; i < cnt; i++) {
                    //console.log('ck ' + i)
                    assert(childComplete[i])
                    assert(childCompleteCalled[i])
                }
                //assert(childComplete)

            })
            worker.on('complete', 't2', function (id, data) {
                assert(childComplete[data.i])
                //console.log('c ' + data.i)
                childCompleteCalled[data.i] = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                for (var i = 0; i < cnt; i++) {
                    //console.log('ck ' + i)
                    assert(childCompleteCalled[i])
                }
                assert(completeCalled)
                done()
            }, 1000)
        })

        it('should handle children hierarchy', function (done) {
            var complete = false
            var child1Complete = false
            var child2Complete = false
            var completeCalled = false
            var child1CompleteCalled = false
            var child2CompleteCalled = false
            worker.on('process', 't1', function (id, data, cb) {
                //console.log('process t1')
                complete = true
                worker.createChildTask(id, 't2', {}, cb)
            })
            worker.on('process', 't2', function (id, data, cb) {
                //console.log('process t2')
                worker.createChildTask(id, 't3', {}, function () {
                })
                setTimeout(function () {
                    child1Complete = true
                    worker.createChildTask(id, 't3', {}, function () {
                    })
                    cb()
                }, 100)
            })
            worker.on('process', 't3', function (id, data, cb) {
                //console.log('process t3')
                setTimeout(function () {
                    child2Complete = true
                    cb()
                }, 100)
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                completeCalled = true
                assert(child2Complete)
                assert(child2CompleteCalled)
                assert(child1Complete)
                assert(child1CompleteCalled)
            })
            worker.on('complete', 't2', function () {
                assert(child1Complete)
                child1CompleteCalled = true
                assert(child2Complete)
                assert(child2CompleteCalled)
            })
            worker.on('complete', 't3', function () {
                assert(child2Complete)
                child2CompleteCalled = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                assert(child1CompleteCalled)
                assert(child2CompleteCalled)
                assert(completeCalled)
                done()
            }, 300)
        })


        it('should handle children hierarchy', function (done) {
            var cnt = 10

            var complete = []
            var completeCalled = []
            for (var i = 0; i < cnt + 1; i++) {
                complete[i] = false
                completeCalled[i] = false
            }
            for (var i = 0; i < cnt; i++) {
                (function () {
                    var ii = i

                    worker.on('process', 't' + ii, function (id, data, cb) {
                        //console.log('process t' + ii)
                        setTimeout(function () {
                            complete[ii] = true
                            worker.createChildTask(id, 't' + (ii + 1), {}, cb)
                        }, 10)
                    })
                })()
            }
            worker.on('process', 't' + cnt, function (id, data, cb) {
                //console.log('process t' + cnt + 'ppp')
                setTimeout(function () {
                    complete[cnt] = true
                    //console.log('deepest childooooooooooooooooooooooo ', id)
                    cb()
                }, 10)
            })
            for (var i = 0; i < cnt + 1; i++) {
                (function () {
                    var ii = i
                    worker.on('complete', 't' + ii, function (id) {
                        //console.log('fail ', ii, ' ', id)
                        for (var j = 0; j < ii; j++) {
                            //assert(!complete[ii])
                            assert(!completeCalled[j])
                        }
                        completeCalled[ii] = true
                        for (var j = ii; j < cnt + 1; j++) {
                            assert(complete[j])
                            assert(completeCalled[j])
                        }

                        //assert(childComplete)

                    })
                })()
            }
            worker.createTask('t0', {}, function () {
            })
            setTimeout(function () {
                for (var i = 0; i < cnt + 1; i++) {
                    assert(completeCalled[i])
                }
                done()
            }, 1500)
        })

        it('should handle failing children', function (done) {
            var complete = false
            var childComplete = false
            var completeCalled = false
            var childCompleteCalled = false
            var i = 0
            worker.on('process', 't1', function (id, data, cb) {
                //console.log('process t1')
                complete = true
                worker.createChildTask(id, 't2', {}, cb)
            })
            worker.on('process', 't2', function (id, data, cb) {
                //console.log('process t2')
                setTimeout(function () {
                    if (++i < 3) {
                        cb(new Error('ups'))
                    } else {
                        childComplete = true
                        cb()
                    }
                }, 50)
            })
            worker.on('complete', 't1', function () {
                assert(complete)
                assert(!completeCalled)
                completeCalled = true
                assert(childComplete)
                assert(childCompleteCalled)

            })
            worker.on('complete', 't2', function () {
                assert(childComplete)
                assert(!completeCalled)
                assert(!childCompleteCalled)
                childCompleteCalled = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                assert(childCompleteCalled)
                assert(completeCalled)
                done()
            }, 300)
        })


        it('should handle failing parent', function (done) {
            var complete = false
            var childComplete = false
            var completeCalled = false
            var childCompleteCalled = false
            var i = 0
            worker.on('process', 't1', function (id, data, cb) {
                //console.log('process t1')
                worker.createChildTask(id, 't2', {}, function () {
                })
                setTimeout(function () {
                    if (++i < 3) {
                        cb(new Error('ups'))
                    } else {
                        complete = true
                        cb()
                    }
                }, 50)
            })
            worker.on('process', 't2', function (id, data, cb) {
                //console.log('process t2')
                childComplete = true
                cb()

            })
            worker.on('complete', 't1', function () {
                assert(complete)
                assert(!completeCalled)
                completeCalled = true
                assert(childComplete)
                assert(childCompleteCalled)

            })
            worker.on('complete', 't2', function () {
                assert(childComplete)
                assert(!completeCalled)
                childCompleteCalled = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                assert(childCompleteCalled)
                assert(completeCalled)
                done()
            }, 300)
        })


        it('should complete when child failures less than max failures', function (done) {
            var i = 0
            var complete1 = false
            var complete1Called = false
            var complete2 = false
            var complete2Called = false
            worker.on('process', 't1', function (id, data, cb) {
                complete1 = true
                worker.createChildTask(id, 't2', {}, {maxFailures:5}, cb)
            })
            worker.on('process', 't2', function (id, data, cb) {
                if (++i < 3) {
                    cb(new Error('ups'))
                } else {
                    complete2 = true
                    cb()
                }
            })
            worker.on('complete', 't1', function () {
                assert(complete1)
                complete1Called = true
            })
            worker.on('complete', 't2', function () {
                assert(complete2)
                complete2Called = true
            })
            worker.createTask('t1', {}, function () {
            })
            setTimeout(function () {
                assert(complete1Called)
                assert(complete2Called)
                done()
            }, 500)
        })
        it('should fail after max child failures', function (done) {
            var i = 0
            var complete1 = false
            var complete1Called = false
            var complete2 = false
            var complete2Called = false
            worker.on('process', 't1', function (id, data, cb) {
                complete1 = true
                worker.createChildTask(id, 't2', {}, {maxFailures:3}, cb)
            })
            worker.on('process', 't2', function (id, data, cb) {
                if (++i < 5) {
                    cb(new Error('ups'))
                } else {
                    complete2 = true
                    cb()
                }
            })
            worker.on('complete', 't1', function () {
                assert(false)
            })
            worker.on('complete', 't2', function () {
                assert(false)
            })
            worker.createTask('t1', {}, {maxFailures:1}, function () {
            })

            setTimeout(done, 500)
        })
    })
})