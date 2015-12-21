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
        "mallet": function (head, req) {
            var row;
            start({
                "headers": {
                    "Content-Type": "text/plain"
                }
            });

            function getFeatures(r) {
                var f = [];


                f.push(str);
                //f.push(r.isPeriod ? 1 : 0);
                f.push(r.isNumber ? 1 : 0);
                f.push(r.isCapitalized ? 1 : 0);
                //f.push(r.isInTop50WordsNr?1:0); //TODO
                //f.push(r.isInTop50WordsTitle?1:0); //TODO
                return f;
            }

            while (row = getRow()) {
                var tokens = row.value;
                for (var i = 0; i < tokens.length; i++) {
                    var token = tokens[i];
                    var str = token[0];
                    var tagName = token[1];
                    var r = ({
                        string: str.replace(/\s/g, ''),
                        isPeriod: !!str.match(/^[\.]+$/),
                        isNumber: !!str.match(/^[0-9\.]+$/),
                        isCapitalized: !!str.match(/^[A-Z]/), //Match uppercase character
                        label: tagName.match(/^(nr|title)$/) ? tagName : "out"
                    });
                    var features = getFeatures(r);
                    send(features.join(" ") + " " + r.label + "\n");
                }
            }
        },
        "xml": function (head, req) {
            var row;
            start({
                "headers": {
                    "Content-Type": "text/xml; charset:utf-8;"
                }
            });

            send("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
            send("<docs>\n");
            while (row = getRow()) {
                send("<doc>\n");
                var tokens = row.value;
                for (var i = 0; i < tokens.length; i++) {
                    var token = tokens[i];
                    var str = token[0];
                    var tagName = token[1];
                    var r = ({
                        string: str.replace(/\s/g, ''),
                        isPeriod: !!str.match(/^[\.]+$/),
                        isNumber: !!str.match(/^[0-9\.]+$/),
                        isCapitalized: !!str.match(/^[A-Z]/), //Match uppercase character
                        label: tagName.match(/^(nr|title)$/) ? tagName : "out"
                    });
                    var strs = ["<token "];
                    for (var field in r) {
                        if (r.hasOwnProperty(field))
                            strs.push(field + "='" + r[field] + "' ");
                    }
                    strs.push("/>\n");
                    send(strs.join(""));
                }
                send("</doc>");
            }
            send("</docs>");
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
