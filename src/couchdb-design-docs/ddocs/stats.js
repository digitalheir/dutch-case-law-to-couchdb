var stringifyFunctions = require('./../stringifyFunctions');

var stats = {
    views: require('./stats/views')
};

module.exports = {
    "_id": "_design/stats",
    "views": stringifyFunctions(stats.views),
    "lists": {
        value_large_enough: "function(head, req) { " +
        "  send(\"[\");" +
        "  var sent=false;" +
        "  var row; while (row = getRow()) { " +
        "    if(typeof row.value == \"number\"&&row.value > 5){" +
        "      if(sent){send(\",\");}" +
        "      send(JSON.stringify(row));" +
        "      sent=true;" +
        "    } " +
        "  } " +
        "  send(\"]\");" +
        "}"
    },
    "rewrites": [],
    "language": "javascript",
    "indexes": {}
};