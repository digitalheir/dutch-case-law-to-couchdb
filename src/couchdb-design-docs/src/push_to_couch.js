var PouchDB = require('pouchdb');
var _ = require('underscore');
var ddocs = require('./ddocs/ddocs');
var secret = require('./secret');

var db = new PouchDB("http://" + secret.username + ".cloudant.com/docs", {
    auth: secret
});


var push = function(ddocs){
db.allDocs(
    {
        keys: _.map(ddocs, function(doc){doc._id}) 
    }
).then(function (res) {
        var revMap = {};
        res.rows.forEach(function (el) {
            revMap[el.id] = el.value.rev;
        });

        ddocs.forEach(function (el) {
            if (revMap[el._id]) {
                el._rev = revMap[el._id];
            }
        });

        return db.bulkDocs({"docs": ddocs});
    }).then(function (res) {
        console.log("Pushed");
    })
    .catch(function (err) {
        console.error(err);
    });
}

module.exports = push;
