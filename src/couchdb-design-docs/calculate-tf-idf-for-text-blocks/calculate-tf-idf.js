"use strict";
const fs = require('fs');
const _ = require('underscore');

var docCount = 0;
let term_frequency_in_titles = Object.create(null);
let doc_frequency_for_terms = Object.create(null);

function tfidf() {
    let result = [];
    for (let term in term_frequency_in_titles) {
        //noinspection JSUnfilteredForInLoop
        let freqInTitle = term_frequency_in_titles[term];
        //noinspection JSUnfilteredForInLoop
        let docCountForTerm = doc_frequency_for_terms[term];
        //noinspection JSUnfilteredForInLoop
        result.push({
            term: term,
            score: (freqInTitle * Math.log(docCount / (1 + docCountForTerm)))
        });
    }
    return _.sortBy(result, function (el) {
        return -el.score;
    });
}


function tf() {
    return [];
}


let createIdf = function (termCount) {
    for (let inTitle in termCount) {
        //noinspection JSUnfilteredForInLoop
        let sections = termCount[inTitle];
        for (let sectionRole in sections) {
            //noinspection JSUnfilteredForInLoop
            let wordsInSectionRole = sections[sectionRole];
            for (let word in wordsInSectionRole) {
                //noinspection JSUnfilteredForInLoop
                let count = doc_frequency_for_terms[word] || 0;
                //noinspection JSUnfilteredForInLoop
                doc_frequency_for_terms[word] = count + wordsInSectionRole[word];
            }
        }
    }
};

let createTf = function (termCount) {
    //let titleBlockCount = data.docCount;
    for (let inTitle in termCount) {
        if (inTitle == 'true') {
            //noinspection JSUnfilteredForInLoop
            let sections = termCount[inTitle];
            for (let sectionRole in sections) {
                //noinspection JSUnfilteredForInLoop
                let wordsInSectionTole = sections[sectionRole];
                for (let word in wordsInSectionTole) {
                    //noinspection JSUnfilteredForInLoop
                    let count = term_frequency_in_titles[word] || 0;
                    //noinspection JSUnfilteredForInLoop
                    term_frequency_in_titles[word] = count + wordsInSectionTole[word];
                }
            }
        } else {
            console.error('???');
        }
    }
};
let idfData = JSON.parse(fs.readFileSync('idf.json', {encoding: 'utf-8'}));
docCount = idfData.docCount;
createIdf(idfData.termDocCount);

let tfData = JSON.parse(fs.readFileSync('tf.json', {encoding: 'utf-8'}));
createTf(tfData.termFrequency);

let result = tfidf();
fs.writeFile('tf-idf.json', JSON.stringify(result), function (err) {
    if (err) {
        console.error(err)
    } else {
        console.log("DOne!")
    }
});