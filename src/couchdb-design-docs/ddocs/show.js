var stringifyFunctions = require('./../stringifyFunctions');

var show = {
    shows: require('./show/shows')
};

module.exports = {
    "_id": "_design/show",
    "shows": stringifyFunctions(show.shows),
    "rewrites": [],
    "language": "javascript",
    "indexes": {}
};