var stringifyFunctions = require('./../stringifyFunctions');


var query = {
    views: require('./query/views'),
    indexes: require('./query/indexes')
};

module.exports = {
    "_id": "_design/query",
    "views": stringifyFunctions(query.views),
    "rewrites": [],
    "language": "javascript",
    "indexes": stringifyFunctions(query.indexes)
};