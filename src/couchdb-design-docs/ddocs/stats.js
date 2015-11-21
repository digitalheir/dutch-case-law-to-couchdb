var stringifyFunctions = require('./../stringifyFunctions');

var stats = {
    views: require('./stats/views')
};

module.exports = {
    "_id": "_design/stats",
    "views": stringifyFunctions(stats.views),
    "rewrites": [],
    "language": "javascript",
    "indexes": {}
};