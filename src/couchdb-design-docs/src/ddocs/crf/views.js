var fs = require('fs');


//console.log(nat);

var functions = {

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