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
    views: require('./query_dev/views')
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
            "language": "javascript"
        }
    ]
};

//console.log(docs[3]);

module.exports = docs;