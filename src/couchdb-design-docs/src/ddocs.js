var fs = require('fs');

var stringifyFunctions = require('./stringifyFunctions');

var stats = {
    views: require('./stats/views')
};
var show = {
    shows: require('./show/shows')
};
var query = {
    views: require('./query/views'),
    indexes: require('./query/indexes')
};
var query_dev = {
    views: require('./query_dev/views'),
    lists: {
        "crf-train": function (head, req) {
            var row;
            start({
                "headers": {
                    "Content-Type": "text/plain"
                }
            });
            while (row = getRow()) {
                send(row.value);
            }
        },
        "crf-test": function (head, req) {

        }
    }
};

var docs = {
    "docs": [
        {
            "_id": "_design/show",
            "shows": stringifyFunctions(show.shows),
            "rewrites": [],
            "language": "javascript",
            "indexes": {}
        },
        {
            "_id": "_design/stats",
            "views": stringifyFunctions(stats.views),
            "rewrites": [],
            "language": "javascript",
            "indexes": {}
        },
        {
            "_id": "_design/query",
            "views": stringifyFunctions(query.views),
            "rewrites": [],
            "language": "javascript",
            "indexes": stringifyFunctions(query.indexes)
        },
        {
            "_id": "_design/query_dev",
            "views": (stringifyFunctions(query_dev.views)),
            "rewrites": [],
            "language": "javascript",
            "lists": stringifyFunctions(query_dev.lists),
            "lib": {
                "natural": fs.readFileSync(__dirname + '/natural.js', {encoding: 'utf-8'}),
                "crfTokenizer": fs.readFileSync(__dirname + '/crf_tokenizer.js', {encoding: 'utf-8'})
            }
        }
    ]
};

//console.log(docs[3]);

module.exports = docs;