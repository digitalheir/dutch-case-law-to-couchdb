var assert = require('assert');
var views = require('../../query_dev/views');
var doc = require('../doc/doc');
var doc_rich = require('../doc/doc_rich');
var doc_hoge_raad = require('../doc/doc_hoge_raad');

function testSecondaryView(f, doc) {
    var emitted = [];
    //noinspection JSUnusedLocalSymbols
    var emit = function (a, b) {
        emitted.push([a, b]);
    };
    f = eval("(" + f.map.toString() + ")");
    f(doc);
    console.log(emitted);
    return emitted;
}

describe('query_dev', function () {
    describe('views', function () {
        describe('views', function () {
            it('should emit doc that is not marked up', function () {
                var emitted = testSecondaryView(views.docs_with_rich_markup, doc);

                assert.equal(emitted.length, 1);
                assert.equal(emitted[0][0][0], false);
                assert.equal(emitted[0][1], 1);
                //assert.equal(emitted[1][0][0], true);
                //assert.equal(emitted[1][1], 0);
            });
            it('should emit doc that is marked up', function () {
                var emitted = testSecondaryView(views.docs_with_rich_markup, doc_rich);
                assert.equal(emitted.length, 1);
                assert.equal(emitted[0][0][0], true);
                assert.equal(emitted[0][1], 1);
                //assert.equal(emitted[1][0][0], false);
                //assert.equal(emitted[1][1], 0);
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