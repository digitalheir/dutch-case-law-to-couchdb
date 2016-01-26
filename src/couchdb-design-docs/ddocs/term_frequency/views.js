var fs = require('fs');

var functions = {
        mirror: {
            map: function (doc) {
                emit(doc.key, doc.value);
            }
        },
        document_frequency: {
            map: function (doc) {
                if (doc.key.length === 3
                    && typeof doc.value == 'number'
                    && typeof doc.key[2] == 'string'
                    && doc.key[2].trim().length > 0) {
                    var Snowball = null;
                    try {
                        //noinspection NodeRequireContents
                        Snowball = require('views/lib/snowball');
                    } catch (err) {
                        //noinspection JSFileReferences
                        Snowball = require('../snowball.js');
                    }
                    var stemmer = new Snowball('Dutch');
                    Snowball = null;

                    var natural = null;
                    try {
                        //noinspection NodeRequireContents
                        natural = require('views/lib/natural');
                    } catch (err) {
                        //noinspection JSFileReferences
                        natural = require('../natural.js');
                    }
                    var tokenizer = new natural.WordPunctTokenizer();


                    var sectionRole = doc.key[0];
                    var inTitle = doc.key[1];
                    var normalized = doc.key[2].trim();

                    var tokens = tokenizer.tokenize(normalized);

                    var stemmedWords = {};
                    for (var i = 0; i < tokens.length; i++) {
                        stemmer.setCurrent(tokens[i]);
                        stemmer.stem();
                        var stemmed = stemmer.getCurrent();

                        if (!stemmedWords[stemmed]) {
                            stemmedWords[stemmed] = true;
                        }
                    }
                    for (var word in stemmedWords) {
                        if (stemmedWords.hasOwnProperty(word)) {
                            //noinspection NodeModulesDependencies
                            emit([sectionRole, inTitle, word], doc.value);
                        }
                    }
                }
            },
            reduce: '_sum'
        }

        ,
        lib: {
            "natural": fs.readFileSync('../natural.min.js', {encoding: 'utf-8'}),
            "snowball": fs.readFileSync('../snowball.js', {encoding: 'utf-8'})
        }
    }
    ;

module.exports = functions;
