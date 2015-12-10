var fs = require('fs');


var functions = {

    crfTestTokens: {
        map: function (doc) {
            function getLib(s) {
                try {
                    return require('views/lib/' + s);
                } catch (err) {
                    return require('../' + s + '.js');
                }
            }

            var CRF_TEST = 1;
            if (doc.useForCrf === CRF_TEST) {
                var xml = getLib('xml_util');
                if (xml.hasTag(doc.xml, "section")) {
                    var crfTokenizer = getLib('crf_tokenizer');
                    var nat = getLib('natural');
                    var tokenizer = new nat.WordPunctTokenizer();

                    //console.log("AAAAA " + xml.findContentNode(doc.xml));
                    var crfTokens = crfTokenizer.tokenize(tokenizer, xml.findContentNode(doc.xml));
                    for (var i = 0; i < crfTokens.length; i++) {
                        emit([doc._id, i], crfTokens[i]);
                    }
                }
            }
        },
        reduce: '_count'
    },
    crfTrainTokens: {
        map: function (doc) {
            var CRF_TRAIN = 0;

            function getLib(s) {
                try {
                    return require('views/lib/' + s);
                } catch (err) {
                    return require('../' + s + '.js');
                }
            }

            if (doc.useForCrf === CRF_TRAIN) {
                var xml = getLib('xml_util');
                if (xml.hasTag(doc.xml, "section")) {
                    var crfTokenizer = getLib('crf_tokenizer');
                    var nat = getLib('natural');
                    var crfTokens = crfTokenizer.tokenize((new nat.WordPunctTokenizer()), xml.findContentNode(doc.xml));
                    for (var i = 0; i < crfTokens.length; i++) {
                        emit([doc._id, i], crfTokens[i]);
                    }
                }
            }
        },
        reduce: '_count'
    },
    lib: {
        "natural": fs.readFileSync('../natural.min.js', {encoding: 'utf-8'}),
        "crf_tokenizer": fs.readFileSync('../crf_tokenizer.min.js', {encoding: 'utf-8'}),
        "xml_util": fs.readFileSync('../xml_util.min.js', {encoding: 'utf-8'})
    }
};

module.exports = functions;
