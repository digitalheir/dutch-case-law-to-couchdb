"use strict";
const fs = require('fs');
const _ = require('underscore');

let writeForEachKind = function (termCount) {
    for (let inTitle in termCount) {
        if (inTitle == 'true') {
            //noinspection JSUnfilteredForInLoop
            let sections = termCount[inTitle];



            for (let sectionRole in sections) {
                //noinspection JSUnfilteredForInLoop
                let wordsInSectionTole = sections[sectionRole];

                let result = _.sortBy(_.map(_.pairs(wordsInSectionTole), function (o) {
                    let word = o[0];
                    let count = o[1];
                    return [word, ((count * 100) / titles_count)];
                }),function(el){
                    return -el[1];
                });


                fs.writeFile('relative-title-frequency/section/'+sectionRole+".json", JSON.stringify(result), function (err) {
                    if (err) {
                        console.error(err)
                    } else {
                        console.log("DOne!")
                    }
                });
            }
        } else {
            console.error('???');
        }
    }
};
let tfData = JSON.parse(fs.readFileSync('tf-per-section.json', {encoding: 'utf-8'}));
var titles_count = tfData.docCount;
writeForEachKind(tfData.termDocCount);