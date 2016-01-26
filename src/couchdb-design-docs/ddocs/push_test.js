var PouchDB = require('pouchdb');
var _ = require('underscore');
var secret = require('./../secret');

var database = new PouchDB("http://" + secret.username + ".cloudant.com/ecli_sample", {
    auth: secret
});


var push = function (ddocs, db) {
    if (!db) db = database;
    console.log("Pushing " + ddocs.length);
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
var stringifyFunctions = require('./../stringifyFunctions');

push([
        {
            "_id": "_design/test",
            "views": stringifyFunctions({
                naked: {
                    map: function (doc) {
                            emit(doc._id, 1);
                    },
                    reduce: '_sum',
                    dbcopy: 'testcopy'
                },
                wrapped: {
                    map: function (doc) {
                            emit([doc._id], 1);
                    },
                    reduce: '_sum',
                    dbcopy: 'testcopy'
                }
            }),
            "lists": {
            },
            "rewrites": [],
            "language": "javascript",
            "indexes": {}
        }
    ]
);
