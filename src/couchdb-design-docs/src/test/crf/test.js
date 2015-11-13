var assert = require('assert');
var views = require('../../ddocs/crf/views');
var doc = require('../doc/doc');
var doc_rich = require('../doc/doc_rich');
var doc_hoge_raad = require('../doc/doc_hoge_raad');
var doc_with_image = require('../doc/doc_with_image');

function testSecondaryView(f, doc) {
    var emitted = [];
    //noinspection JSUnusedLocalSymbols
    var emit = function (a, b) {
        emitted.push([a, b]);
    };
    f = eval("(" + f.map.toString() + ")");
    f(doc);
    //console.log(emitted);
    return emitted;
}

function testSecondaryViewOnDocs(f, docs) {
    var emitted = [];
    //noinspection JSUnusedLocalSymbols
    var emit = function (a, b) {
        emitted.push([a, b]);
    };
    f = eval("(" + f.map.toString() + ")");
    //console.log(docs.length)
    for (var i = 0; i < docs.length; i++) {
        f(docs[i]);
    }
    //console.log(emitted);
    return emitted;
}

describe('crf', function () {
    describe('views', function () {
        it('should tokenize', function () {
            var t = require('../../crf_tokenizer');
            var nat = require('../../natural');
            var tokens = t.tokenize(new nat.WordPunctTokenizer(), doc_rich.simplifiedContent);
            assert.equal(tokens.length, 1213);
        });

        it('should correctly emit parents of <nr> tags', function () {
            var emitted = testSecondaryViewOnDocs(views.parentsOfNr, [doc, doc_rich]);
            assert.equal(emitted.length, 11);
            assert.equal(emitted[0][0][0], 'paragroup');
        });
    });

});