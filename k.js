var kue = require('kue');
var events = require('kue/lib/queue/events');

// create our job queue

var jobs = kue.createQueue();
var Job = kue.job;
// start redis with $ redis-server

// create some jobs at random,
// usually you would create these
// in your http processes upon
// user input etc.


var p = jobs.create('parent', {
    title:'parent',
    children:{}
});

p.save();

jobs.process('parent', 1, function (job, done) {
    for(var i = 0; i < 100; i++){
    var c = jobs.create('child', {
        title:'parent',
        parent:job.id
    }).attempts(3);
    c.save(function (e) {
        if (e) {
            return done(e);
        }
        job.data.children[c.id] = false;
        job.update(function (e) {
            if (e) {
                return done(e);
            }
            //done();
        })
    });
    }
    done();
});
var i = 0;
jobs.process('child', 100, function (job, done) {
    console.log("processing child");
    setTimeout(function () {
        done(++i < 3 ? new Error("nooo") : null);
    }, Math.random() * 2000 | 0);
});
jobs.on('job child complete', function (id) {
    console.log('event catched')
});
function childComplete (parentId, childId) {
    kue.Job.get(parentId, function (e, parent) {
        if (e) {
            return console.log(e);
        }
        if (!parent) {
            return console.log("Parent is null")
        }
        console.log(JSON.stringify(parent));
        parent.data.children[childId] = true;
        parent.update(function (e) {
            if (e) {
                return console.log(e);
            }
            console.log("parent updated");
            var all = true;
            for(var i in parent.data.children)
                if (!parent.data.children[i]) {
                    all = false;
                    break;
                }
            if (all) {
                console.log('all children complete')
            }

        })
    });
}

jobs.on('job complete', function (id) {
    console.log('some complete job!!!');
    //throw new Error("stack tracer")
    kue.Job.get(id, function (e, job) {
        if (e) {
            return console.log(e);
        }
        if (!job) {
            return console.log("Job is null");
        }
        if (job.type === "parent") {
            return console.log("parent complete!!!");
        }
        console.log('child complete!!!');
        if (job.data.parent) {
            childComplete(job.data.parent, job.id);
//
        }


    })
});

