var stringifyFunctions = require('../stringifyFunctions');


//console.log(nat);

var functions = {
    hoge_raad_by_date: {
        map: function (doc) {
            if (doc['creator'] && doc['creator']['@id']) {
                if (doc['creator']['@id'].match(/Hoge_Raad/)) {
                    var d = new Date(doc['date']);
                    emit(
                        [
                            d.getFullYear(),
                            d.getMonth() + 1,
                            d.getDate()
                        ], 1
                    );
                }
            }
        },
        reduce: '_count'
    },
    untagged_docs_with_section_tag: {
        map: function (doc) {
            function hasSectionTag(o) {
                for (var f in o) {
                    if (o.hasOwnProperty(f)) {
                        if (f.match(/section/g)) {
                            return true;
                        } else {
                            if (typeof o[f] == 'object' &&
                                hasSectionTag(o[f])) {
                                return true;
                            }
                        }
                    }
                }
                return false;
            }

            if (doc.corpus == 'Rechtspraak.nl') {
                if (!doc.useForCrf) {
                    var hasS = hasSectionTag(doc.simplifiedContent);
                    var d = new Date(doc['date']);
                    emit(
                        [
                            hasS,
                            d.getFullYear(),
                            d.getMonth() + 1,
                            d.getDate()
                        ], 1
                    );
                    //emit(
                    //    [
                    //        !isMarkedUp,
                    //        d.getFullYear(),
                    //        d.getMonth() + 1,
                    //        d.getDate()
                    //    ], 0
                    //);
                }
            }
        }
        ,
        reduce: "_sum"
    },
    docs_with_section_tag: {
        map: function (doc) {
            function hasSectionTag(o) {
                for (var f in o) {
                    if (o.hasOwnProperty(f)) {
                        if (f.match(/section/g)) {
                            return true;
                        } else {
                            if (typeof o[f] == 'object' &&
                                hasSectionTag(o[f])) {
                                return true;
                            }
                        }
                    }
                }
                return false;
            }

            if (doc.corpus == 'Rechtspraak.nl') {
                var hasS = hasSectionTag(doc.simplifiedContent);
                var d = new Date(doc['date']);
                emit(
                    [
                        hasS,
                        d.getFullYear(),
                        d.getMonth() + 1,
                        d.getDate()
                    ], 1
                );
                //emit(
                //    [
                //        !isMarkedUp,
                //        d.getFullYear(),
                //        d.getMonth() + 1,
                //        d.getDate()
                //    ], 0
                //);

            }
        }
        ,
        reduce: "_sum"
    },
    sectionNrs: {
        map: function (doc) {
            function getString(o) {
                if (typeof o == 'string') {
                    return o;
                } else {
                    var sb = [];
                    for (var i in o) {
                        if (o.hasOwnProperty(i)) {
                            sb.push(getString(o[i]));
                        }
                    }
                    return sb.join('');
                }
            }

            function getTitles(o) {
                var titles = [];
                for (var tagName in o) {
                    if (o.hasOwnProperty(tagName)) {
                        if (tagName == "nr") {
                            titles.push(getString(o[tagName]));
                        } else {
                            if (typeof o[tagName] == 'object') {
                                // Append titles for inner object to titles object
                                titles.push.apply(titles, getTitles(o[tagName]));
                            }
                        }
                    }
                }
                return titles;
            }

            if (doc.simplifiedContent) {
                var tts = getTitles(doc.simplifiedContent);
                for (var i = 0; i < tts.length; i++) {
                    emit(tts[i].toLowerCase(), 1);
                }
            }
        },
        reduce: "_sum"
    },
    sectionTitles: {
        map: function (doc) {
            function getString(o) {
                if (typeof o == 'string') {
                    return o;
                } else {
                    var sb = [];
                    for (var i in o) {
                        if (o.hasOwnProperty(i)) {
                            sb.push(getString(o[i]));
                        }
                    }
                    return sb.join('');
                }
            }

            function getTitles(o) {
                var titles = [];
                for (var tagName in o) {
                    if (o.hasOwnProperty(tagName)) {
                        if (tagName == "title") {
                            titles.push(getString(o[tagName]));
                        } else {
                            if (typeof o[tagName] == 'object') {
                                // Append titles for inner object to titles object
                                titles.push.apply(titles, getTitles(o[tagName]));
                            }
                        }
                    }
                }
                return titles;
            }

            if (doc.simplifiedContent) {
                var tts = getTitles(doc.simplifiedContent);
                for (var i = 0; i < tts.length; i++) {
                    emit(tts[i].toLowerCase(), 1);
                }
            }
        },
        reduce: "_sum"
    },
    crfTestTokens: {
        map: function (doc) {
            if (doc.useForCrf == "test") {
                var crfTokenizer = require('lib/crfTokenizer');
                var crfTokens = crfTokenizer.tokenize(require('lib/natural').WordPunctTokenizer(), doc.simplifiedContent);
                for (var i in crfTokens) {
                    if (crfTokens.hasOwnProperty(i)) {
                        emit([doc._id, i], crfTokens[i]);
                    }
                }

            }
        }
    },
    crfTrainTokens: {
        map: function (doc) {
            if (doc.useForCrf == "train") {
                var crfTokenizer = require('lib/crfTokenizer');
                var crfTokens = crfTokenizer.tokenize(require('lib/natural').WordPunctTokenizer(), doc.simplifiedContent);
                for (var i in crfTokens) {
                    if (crfTokens.hasOwnProperty(i)) {
                        emit([doc._id, i], crfTokens[i]);
                    }
                }
            }
        }
    },
    parentsOfNr: {
        map: function (doc, tagName) {
            var emitNrParents = function (o) {
                for (var field in o) {
                    if (o.hasOwnProperty(field)) {
                        if (field == 'nr') {
                            emit([doc._id, tagName], 1);
                        } else if (typeof o[field] == 'object') {
                            //TODO is arraylike
                            emitNrParents(o[field], field);
                        }
                    }
                }
            };

            if (doc.simplifiedContent) {
                emitNrParents(doc.simplifiedContent);
            }
        },
        reduce: "_sum"
    },
    docs_with_image: {
        map: function (doc) {
            function hasAfbeelding(obj) {
                //console.log(obj);
                for (var field in obj) {
                    if (obj.hasOwnProperty(field)) {
                        if (field == 'imageobject') {
                            return true;
                        }
                        var children = obj[field];
                        for (var i = 0; i < children.length; i++) {
                            var child = children[i];
                            if (typeof child == 'object') {
                                if (hasAfbeelding(children[i])) {
                                    return true;
                                }
                            }
                        }
                    }
                }
                return false;
            }

            if (doc.simplifiedContent) {
                //console.log(doc.simplifiedContent)
                //return;
                if (hasAfbeelding(doc.simplifiedContent)) {
                    emit(
                        [
                            doc._id
                        ], 1
                    );
                }
                //emit(
                //    [
                //        !isMarkedUp,
                //        d.getFullYear(),
                //        d.getMonth() + 1,
                //        d.getDate()
                //    ], 0
                //);

            }
        },
        reduce: "_sum"
    }
};

module.exports = functions;