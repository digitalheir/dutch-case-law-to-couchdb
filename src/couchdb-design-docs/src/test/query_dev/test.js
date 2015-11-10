var assert = require('assert');
var views = require('../../query_dev/views');
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

describe('query_dev', function () {
    describe('views', function () {
        describe('views', function () {
            it('should emit doc that has section tag', function () {
                var emitted = testSecondaryViewOnDocs(views.docs_with_section_tag, [doc, doc_rich]);

                assert.equal(emitted.length, 2);
                assert.equal(emitted[0][0][0], false);
                assert.equal(emitted[1][0][0], true);
                assert.equal(emitted[0][1], 1);
                assert.equal(emitted[1][1], 1);
                //assert.equal(emitted[1][0][0], true);
                //assert.equal(emitted[1][1], 0);
            });
            it('should emit doc with image', function () {
                var emitted = testSecondaryViewOnDocs(views.docs_with_image, [doc_with_image, doc_rich]);
                assert.equal(emitted.length, 1);
                //assert.equal(emitted[0][0][0], true);
                //assert.equal(emitted[0][1], 1);
            });
        });
    });


    describe('views', function () {
        it('should index hoge raad', function () {
            var emitted = testSecondaryView(views.hoge_raad_by_date, doc_hoge_raad);
            assert.equal(emitted.length, 1);
            assert.equal(emitted[0][0][0], 1984);
            assert.equal(emitted[0][0][1], 1);
            assert.equal(emitted[0][0][2], 17);
        });
        it('should index ecli_last_modified', function () {
            //assert.equal(true, true);
        });
    });

});