var worker = require('./worker')
cnt = 0
worker.on('t1', function(id, data, cb) {
    console.log('$processing...')
    setTimeout(function() {
        if (Math.random() < 0.4) {
            console.log('complete! ' + ++cnt)
            cb()
        } else {
            console.log('ups1!')
            cb(new Error('Ups'))
        }
    }, 1000)
})

worker.start()