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

function stringifyFunctions(o) {
    if (typeof o == 'function') {
        return o.toString();
    } else if (typeof o == 'object') {
        var map = {};
        for (var functionName in o) {
            if (o.hasOwnProperty(functionName)) {
                map[functionName] = stringifyFunctions(o[functionName]);
            }
        }
        return map;
    } else if (typeof o == 'string') {
        return o;
    } else {
        throw Error(o + '???');
    }
}

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
            "views": stringifyFunctions(query_dev.views),
            "rewrites": [],
            "language": "javascript"
        }
    ]
};

//console.log(JSON.stringify(docs));

module.exports = docs;