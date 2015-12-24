var assert = require('assert');
var xml = require('../xml_util');
var stats_views = require('../ddocs/stats/views');
var doc = require('./doc/doc');
var doc_rich = require('./doc/doc_rich');
var doc_hoge_raad = require('./doc/doc_hoge_raad');
var doc_with_image = require('./doc/doc_with_image');
var doc = {
        "xml": [9, [[1, "open-rechtspraak", ["\n  ",


            [1, "section", ["\n        ",
                [1, "title",
                    [
                        "Infor",
                        "Ik stel",
                        "en:"
                    ]
                ], "\n        ", [1, "para"], "\n      "]],
            "\n      ",

            "\n    "],
            ["lang", "nl"], ["xml:space", "preserve"], ["xmlns", "http://www.rechtspraak.nl/schema/rechtspraak-1.0"], ["xmlns:xlink", "http://www.w3.org/1999/xlink"], ["xmlns:xsd", "http://www.w3.org/2001/XMLSchema"], ["xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance"]]],
            "\n"]
    }
    ;

var emitted = [];
//noinspection JSUnusedLocalSymbols
var emit = function (a, b) {
    emitted.push([a, b]);
};


var emitRecursive = function (node) {
    if (typeof node == 'string') {
        var normalized = node.trim().toLowerCase();
        if (normalized.length > 0)
            emit([normalized, doc._id], 1);//Don't emit whitespace
    } else {
        if (xml.getTagName(node) != 'nr') { // Ignore nr tag


            console.log("for child of: " + node);
            xml.forAllChildren(node, function (child) {
                console.log(child);
                emitRecursive(child);
            });
        }
    }
};

var emitNrText = function (node) {
    xml.forAllChildren(node, function (child) {
        if (xml.getTagName(node) == 'title') {
            console.log("FOUND!!!")
            emitRecursive(node);
        } else {
            emitNrText(child);
        }
    });
};

emitNrText(doc.xml);