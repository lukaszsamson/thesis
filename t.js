
var createTask = require('./manager').createTask





var cnt = 0
for (var cnt = 0; cnt < 100; cnt++) {
    (function() {
        var i = cnt;
    createTask('t1', {s: i}, function(e, id) {
        if (e) return console.log(e)
        console.log('requested task id: ' + id)

    })
    })()
}