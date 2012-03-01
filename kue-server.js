var express = require('express')
	, kue = require('kue');

// start the UI
var app = express.createServer();
app.use(kue.app);
app.listen(3333);
console.log('UI started on port 3333');