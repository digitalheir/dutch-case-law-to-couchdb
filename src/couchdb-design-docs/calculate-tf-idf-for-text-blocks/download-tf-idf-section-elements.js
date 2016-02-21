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

var tfViews = require('./views');


//////////////////////////////////////////////////////////////////////////////////////

var titleCount = 0;
var tfRes = Object.create(null);
var idfTitle = Object.create(null);

var docCount = 0;
var idfRes = Object.create(null);
var i = 0;

//noinspection JSUnresolvedFunction
oboe('https://rechtspraak.cloudant.com/docs/_design/stats/_view/docs_with_section_tag?reduce=false&include_docs=true&startkey=[true]')
    .node('!.rows.*', function (row) {
        var idfEmitted = testSecondaryView(
            tfViews.idf, row.doc
        );
        if (idfEmitted.length > 0) {
            //console.log('idf emitted ', idfEmitted.length);
            for (let i = 0; i < idfEmitted.length; i++) {
                let b = idfEmitted[i];
                let key = b[0];
                let val = b[1];

                if (key === 603) {
                    docCount += val;
                } else {
                    let inTitle = key[0];
                    let role = key[1];
                    let word = key[2];

                    let forInTitle = idfRes[inTitle + ""] || Object.create(null);
                    let forRole = forInTitle[role] || Object.create(null);
                    let forWord = forRole[word] || 0;

                    forRole[word + ""] = forWord + val;
                    forInTitle[role + ""] = forRole;
                    idfRes[inTitle + ""] = forInTitle;
                }
            }
            //console.log(res);
        }

        var tfEmitted = testSecondaryView(
            tfViews.tf, row.doc
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

                    let isInTitle = key[0];
                    let role = key[1];
                    let word = key[2];

                    let forInTitle = tfRes[isInTitle + ""] || Object.create(null);
                    let forRole = forInTitle[role] || Object.create(null);
                    let forWord = forRole[word] || 0;

                    forRole[word + ""] = forWord + val;
                    forInTitle[role + ""] = forRole;
                    tfRes[isInTitle + ""] = forInTitle;


                    let dfForInTitle = idfTitle[isInTitle + ""] || Object.create(null);
                    let dfForRole = dfForInTitle[role] || Object.create(null);
                    let dfForWord = dfForRole[word] || 0;

                    dfForRole[word + ""] = dfForWord + 1;
                    dfForInTitle[role + ""] = dfForRole;
                    idfTitle[isInTitle + ""] = dfForInTitle;
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
    //console.log(finalJson);  // logs: {"rows":[]}
    fs.writeFile('idf.json', JSON.stringify(
        {docCount: docCount, termDocCount: idfRes}
    ), function (err) {
        if (err) throw err;
        console.log('idf saved!');
    });
    fs.writeFile('tf-sections.json', JSON.stringify({
        docCount: titleCount,
        termDocCount: idfTitle,
        termFrequency: tfRes
    }), function (err) {
        if (err) throw err;
        console.log('tf saved!');
    });
});
