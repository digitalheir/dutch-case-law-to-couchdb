var stringifyFunctions = require('./../stringifyFunctions');

var query_dev = {
    views: require('./query_dev/views')
};

module.exports = {
    "_id": "_design/query_dev",
    "views": (stringifyFunctions(query_dev.views)),
    "rewrites": [],
    "language": "javascript"
};