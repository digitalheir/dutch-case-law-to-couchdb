var fs = require('fs');


//console.log(nat);

var functions = {

    crfTestTokens: {
        map: function (doc) {
            if (doc.useForCrf == "test") {
                var crfTokenizer = require('views/lib/crfTokenizer');
                var nat = require('views/lib/natural');
                var tokenizer = new nat.WordPunctTokenizer();

                var crfTokens = crfTokenizer.tokenize(tokenizer, doc.xml);
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
                var crfTokens = crfTokenizer.tokenize((new nat.WordPunctTokenizer()), doc.xml);
                for (var i in crfTokens) {
                    if (crfTokens.hasOwnProperty(i)) {
                        emit([doc._id, i], crfTokens[i]);
                    }
                }
            }
        }
    },
    lib: {
        "natural": fs.readFileSync('../natural.min.js', {encoding: 'utf-8'}),
        "crfTokenizer": fs.readFileSync('../crf_tokenizer.min.js', {encoding: 'utf-8'})
    }
};

module.exports = functions;