var PouchDB = require('pouchdb');
var _ = require('underscore');
var secret = require('./../secret');

var database = new PouchDB("https://" + secret.username + ".cloudant.com/docs", {
    auth: secret
});


var push = function (ddocs, db) {
    if(typeof db == 'string'){
        db = new PouchDB("https://" + secret.username + ".cloudant.com/"+db, {
            auth: secret
        });
    }else if (!db){
        db = database;
    }
    console.log("Pushing " + ddocs.length +"  ");
    //console.log(db);
    db.allDocs(
        {
            keys: _.map(ddocs, function (doc) {
                return doc._id;
            })
        }
    ).then(function (res) {
        var revMap = {};
        res.rows.forEach(function (el) {
            if (el.value)
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
};

module.exports = push;
