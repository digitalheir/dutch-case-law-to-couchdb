var stringifyFunctions = require('../stringifyFunctions');
var fs = require('fs');


//console.log(nat);

var functions = {
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

            function getNrs(o) {
                var titles = [];
                for (var tagName in o) {
                    if (o.hasOwnProperty(tagName)) {
                        if (tagName == "nr") {
                            titles.push(getString(o[tagName]));
                        } else {
                            if (typeof o[tagName] == 'object') {
                                // Append titles for inner object to titles object
                                titles.push.apply(titles, getNrs(o[tagName]));
                            }
                        }
                    }
                }
                return titles;
            }

            if (doc.simplifiedContent) {
                var tts = getNrs(doc.simplifiedContent);
                for (var i = 0; i < tts.length; i++) {
                    emit([tts[i], doc._id].toLowerCase(), 1);
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
                            if (typeof o == 'string') {
                                titles.push(o);
                            } else {
                                for (var i = 0; i < o.length; i++) {
                                    if (typeof o[i] == 'string') {
                                        titles.push(o[i]);
                                    }
                                }
                            }
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
                    emit([tts[i].toLowerCase(), doc._id], 1);
                }
            }
        },
        reduce: "_sum"
    },
    crfTestTokens: {
        map: function (doc) {
            if (doc.useForCrf == "test") {
                var crfTokenizer = require('views/lib/crfTokenizer');
                var nat = require('views/lib/natural');
                var tokenizer = new nat.WordPunctTokenizer();

                var crfTokens = crfTokenizer.tokenize(tokenizer, doc.simplifiedContent);
                for (var i = 0; i < crfTokens.length; i++) {
                    emit([doc._id, i], crfTokens[i]);
                }

            }
        }
    },
    crfTrainTokens: {
        map: function (doc) {
            if (doc.useForCrf == "train") {
                var crfTokenizer = require('lib/crfTokenizer');
                var nat = require('views/lib/natural');
                var crfTokens = crfTokenizer.tokenize((new nat.WordPunctTokenizer()), doc.simplifiedContent);
                for (var i in crfTokens) {
                    if (crfTokens.hasOwnProperty(i)) {
                        emit([doc._id, i], crfTokens[i]);
                    }
                }
            }
        }
    },
    parentsOfNr: {
        map: function (doc) {
            var property = function (key) {
                return function (obj) {
                    return obj == null ? void 0 : obj[key];
                };
            };
            var MAX_ARRAY_INDEX = Math.pow(2, 53) - 1;
            var getLength = property('length');
            var isArrayLike = function (collection) {
                var length = getLength(collection);
                return typeof length == 'number' && length >= 0 && length <= MAX_ARRAY_INDEX;
            };

            var emitNrParents = function (o, tagName) {
                for (var field in o) {
                    if (o.hasOwnProperty(field)) {
                        if (field == 'nr') {
                            emit([tagName,doc._id], 1);
                        } else if (typeof o[field] == 'string') {
                        } else if (isArrayLike(o)) {
                            emitNrParents(o[field], tagName);
                        } else {
                            emitNrParents(o[field], field);
                        }
                    }
                }
            };

            if (doc.simplifiedContent) {
                emitNrParents(doc.simplifiedContent, undefined);
            }
        },
        reduce: "_sum"
    },
    lib: {
        "natural": fs.readFileSync('./natural.min.js', {encoding: 'utf-8'}),
        "crfTokenizer": fs.readFileSync('./crf_tokenizer.min.js', {encoding: 'utf-8'})
    }
};

module.exports = functions;