var assert = require('assert');
var views = require('../../query_dev/views');
var doc = require('../doc/doc');
var doc_rich = require('../doc/doc_rich');

describe('query_dev', function () {
    describe('views', function () {
        describe('views', function () {
            var emitted = [];
            var emit = function (a, b) {
                emitted.push([a, b]);
            };
            it('should not emit doc that is not marked up', function () {
                var f = eval("(" + views.docs_with_rich_markup.map.toString() + ")");
                f(doc);

                assert.equal(
                    emitted.length, 0
                );
            });
            it('should emit doc that is richly marked up', function () {
                var f = eval("(" + views.docs_with_rich_markup.map.toString() + ")");
                f(doc_rich);
                assert.equal(
                    emitted[0][0][0], 2002
                );
                assert.equal(
                    emitted[0][0][1], 1
                );
                assert.equal(
                    emitted[0][0][2], 30
                );
            });
        });
    });


    describe('views', function () {
        describe('ecli_last_modified', function () {
            it('should show correctly', function () {
                //assert.equal(true, true);
            });
        });
    });
});    