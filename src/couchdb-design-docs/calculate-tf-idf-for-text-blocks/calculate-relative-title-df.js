"use strict";
const fs = require('fs');
const _ = require('underscore');

let flattenDocCount = function (termCount) {
    var o = Object.create(null);
    for (let inTitle in termCount) {
        if (inTitle == 'true') {
            //noinspection JSUnfilteredForInLoop
            let sections = termCount[inTitle];
            for (let sectionRole in sections) {
                //noinspection JSUnfilteredForInLoop
                let wordsInSectionTole = sections[sectionRole];
                for (let word in wordsInSectionTole) {
                    //noinspection JSUnfilteredForInLoop
                    let count = o[word] || 0;
                    //noinspection JSUnfilteredForInLoop
                    o[word] = count + wordsInSectionTole[word];
                }
            }
        } else {
            console.error('???');
        }
    }
    return o;
};
let tfData = JSON.parse(fs.readFileSync('tf.json', {encoding: 'utf-8'}));
var titles_count = tfData.docCount;
let term_count_in_docs = flattenDocCount(tfData.termDocCount);


let result = _.sortBy(_.map(_.pairs(term_count_in_docs), function (o) {
    let word = o[0];
    let count = o[1];
    return [word, ((count * 100) / titles_count)];
}),function(el){
    return -el[1];
});

fs.writeFile('relative-title-frequency/relative-doc-frequency-title.json', JSON.stringify(result), function (err) {
    if (err) {
        console.error(err)
    } else {
        console.log("DOne!")
    }
});