var PouchDB = require('pouchdb');
var ddocs = require('./ddocs');
var secret = require('./secret');

var db = new PouchDB("http://" + secret.username + ".cloudant.com/docs", {
    auth: secret
});

db.allDocs(
    {
        startkey: '_design',
        endkey: '_e'
    }
).then(function (res) {
        var revMap = {};
        res.rows.forEach(function (el) {
            revMap[el.id] = el.value.rev;
        });
        ddocs.docs.forEach(function (el) {
            if (revMap[el._id]) {
                el._rev = revMap[el._id];
            }
        });

        return db.bulkDocs(ddocs);
    }).then(function (res) {
        console.log("Pushed");
    })
    .catch(function (err) {
        console.error(err);
    });

