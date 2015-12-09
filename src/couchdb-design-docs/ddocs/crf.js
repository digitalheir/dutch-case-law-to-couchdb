var stringifyFunctions = require('./../stringifyFunctions');

var exampleRow = {
    id: "ECLI:NL:CBB:2013:101",
    key: [
        "ECLI:NL:CBB:2013:101",
        "0"
    ],
    value: {
        string: " ",
        tag: "open-rechtspraak",
        isPeriod: false,
        isNumber: false,
        isCapitalized: false
    }
};
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

            function getFeatures(r) {
                var f = [];

                var str = r.string;

                f.push(str);
                //f.push(r.isPeriod ? 1 : 0);
                f.push(r.isNumber ? 1 : 0);
                f.push(r.isCapitalized ? 1 : 0);
                //f.push(r.isInTop50WordsNr?1:0); //TODO
                //f.push(r.isInTop50WordsTitle?1:0); //TODO
                return f;
            }

            while (row = getRow()) {
                var token = row.value;
                var features = getFeatures(row.value);
                var label = token.tag.match(/^(nr|title)$/) ? token.tag : "out";
                send(features.join(" ") + " " + label + "\n");
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
