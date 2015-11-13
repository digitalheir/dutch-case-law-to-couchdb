var stringifyFunctions = require('./../stringifyFunctions');

var crf = {
    views: require('./crf/views'),
    lists: {
        "crf-train": function (head, req) {
            var row;
            start({
                "headers": {
                    "Content-Type": "text/plain"
                }
            });
            while (row = getRow()) {
                var token = row.value;
                var label = token.tag.match(/^(nr|title)$/) ? token.tag : "out";
                send(label + "\n");
            }
        },
        "crf-test": function (head, req) {
            //TODO
        }
    }
};

module.exports = {
    "_id": "_design/crf",
    "views": (stringifyFunctions(crf.views)),
    "lists": stringifyFunctions(crf.lists),
    "rewrites": [],
    "language": "javascript"
};
