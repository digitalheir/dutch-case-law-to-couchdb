var stringifyFunctions = require('./../stringifyFunctions');

var emit_sections = {
    views: require('./emit_sections/views')
};

module.exports = {
    "_id": "_design/emit_sections",
    "views": stringifyFunctions(emit_sections.views),
    "lists": {},
    "rewrites": [],
    "language": "javascript",
    "indexes": {}
};