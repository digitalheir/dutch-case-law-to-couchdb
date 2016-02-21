"use strict";

var https = require('https');
var assert = require('assert');
var fs = require('fs');
var oboe = require('oboe');

var doc = require('./../test/doc/doc');
var doc_rich = require('./../test/doc/doc_rich');
var doc_hoge_raad = require('./../test/doc/doc_hoge_raad');
var doc_with_image = require('./../test/doc/doc_with_image');

function testSecondaryView(f, doc) {
    var emitted = [];
    //noinspection JSUnusedLocalSymbols
    var emit = function (a, b) {
        emitted.push([a, b]);
    };
    f = eval("(" + f.map.toString() + ")");
    f(doc);
    //console.log(emitted);
    return emitted;
}

var tfViews = require('../ddocs/offline/views');


//////////////////////////////////////////////////////////////////////////////////////

var titleCount = 0;
var tfRes = Object.create(null);
var idfInfo = Object.create(null);

var i = 0;

//noinspection JSUnresolvedFunction
var url = 'https://rechtspraak.cloudant.com/docs/_design/stats/_view/docs_with_info_tag?reduce=false&include_docs=true' +
    '&startkey=[true]';
console.log(url);
oboe(url
    //+'&limit=10'
)
    .node('!.rows.*', function (row) {
        var tfEmitted = testSecondaryView(
            tfViews.tfInfoTag, row.doc
        );
        if (tfEmitted.length > 0) {
            //console.log('tf emitted ', tfEmitted.length);
            for (let tfl = 0; tfl < tfEmitted.length; tfl++) {
                let b = tfEmitted[tfl];

                let val = b[1];
                let key = b[0];

                if (key === 603) {
                    titleCount += val;
                } else {
                    let word = key[0];

                    idfInfo[word + ""] = (idfInfo[word + ""]||0) + 1;

                    let forWord = tfRes[word] || 0;
                    tfRes[word + ""] = forWord + val;
                }
            }
        }
        i++;
        if (i % 100 == 0) {
            console.log(i, row.doc._id);
        }
        return oboe.drop;
    }).done(function () {
    // most of the nodes have been dropped
    console.log("done");  // logs: {"rows":[]}

    fs.writeFile('tf-info.json', JSON.stringify({
        docCount: titleCount,
        termDocCount: idfInfo,
        termFrequency: tfRes
    }), function (err) {
        if (err) throw err;
        console.log('tf saved!');
    });
});
