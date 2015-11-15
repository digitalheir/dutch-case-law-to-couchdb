var fs = require('fs');

var functions = {
    parents_of_nr: {
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
                            emit([doc._id, tagName], 1);
                        } else if (isArrayLike(o[field])) {
                            for (var i = 0; i < o[field].length; i += 1) {
                                emitNrParents(o[field][i], tagName);
                            }
                        } else if (typeof o[field] == 'object') {
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
    words_in_title: {
        map: function (doc) {
            function hasTag(obj, tag) {
                if (typeof obj == "object") {
                    for (var field in obj) {
                        if (obj.hasOwnProperty(field)) {
                            if (field == tag) {
                                return true;
                            } else if (hasTag(obj[field], tag)) {
                                return true;
                            }
                        }
                    }
                }
                return false;
            }

            if (doc.simplifiedContent && hasTag(doc.simplifiedContent, "title")) {
                var nat = null;
                try {
                    nat = require('views/lib/natural');
                } catch (err) {
                    nat = require('natural');
                }
                var tokenizer = new nat.WordPunctTokenizer();

                var emitRecursive = function (o) {
                    if (typeof o == 'string') {
                        var tokens = tokenizer.tokenize(o);
                        for (var i = 0; i < tokens.length; i++) {
                            var token = tokens[i].toLowerCase().trim();
                            emit([token, doc._id], 1);
                        }
                    } else if (typeof o == 'object') {
                        for (var field in o) {
                            if (o.hasOwnProperty(field)) {
                                emitRecursive(o[field]);
                            }
                        }
                    }
                };

                var emitTitleTokens = function (o) {
                    for (var field in o) {
                        if (o.hasOwnProperty(field)) {
                            if (field == 'title') {
                                emitRecursive(o[field]);
                            } else if (typeof o[field] == 'string') {
                            } else if (typeof o[field] == 'object') {
                                emitTitleTokens(o[field]);
                            }
                        }
                    }
                };

                emitTitleTokens(doc.simplifiedContent);
            }
        },
        reduce: "_sum"
    },
    section_nrs: {
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
                    var token = tts[i].toLowerCase();
                    emit([token, doc._id], 1);
                }
            }
        },
        reduce: "_sum"
    },
    section_titles: {
        map: function (doc) {
            function emitAllStrings(o) {
                if (typeof o == 'string') {
                    emit([o.toLowerCase(),doc._id],1);
                } else  if (typeof o == 'object'){
			for (var i in o) {
                            if (o.hasOwnProperty(i)) {
				emitAllStrings(o[i]);
                }
}
}
            }

            function emitTitles(o) {
                for (var tagName in o) {
                    if (o.hasOwnProperty(tagName)) {
			var obj = o[tagName];
                         if (tagName == "title") {
				emitAllStrings(obj);
                         } else if (typeof obj == 'object'){
				emitTitles(obj);
                         }
                    }
                }
            }

            if (doc.simplifiedContent) {
                emitTitles(doc.simplifiedContent);
            }
        },
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

            }
        }
        , reduce: "_sum"
    },
    lib: {
        "natural": fs.readFileSync('./natural.min.js', {encoding: 'utf-8'}),
        "crfTokenizer": fs.readFileSync('./crf_tokenizer.min.js', {encoding: 'utf-8'})
    }
};

module.exports = functions;
