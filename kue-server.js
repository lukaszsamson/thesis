var kue = require('kue');

kue.app.listen(3333, function(error) {
    if (error)
        return console.log(error);
    console.log('UI started on port 3333');
});