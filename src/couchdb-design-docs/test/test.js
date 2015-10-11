var assert = require("assert");
var doc = require("./doc/doc");
var fs = require("fs");
var doc_search_index = require("./doc/doc_search_index");

var ddocs = require('../src/ddocs');

describe('query', function () {
    describe('indexes', function () {
        describe('search', function () {
            var indexes = {};
            var index = function (fieldName, strValue, options) {
                indexes[fieldName] = [strValue, options];
            };
            var search = query_indexes.search;
            search(doc);
            it('should index inner text', function () {
                assert.equal(indexes.innerText[0].startsWith('College van Beroep voor het bedrijfsleven'), true);
            });
            it('should index like we expect', function () {
                assert.equal(JSON.stringify(doc_search_index), JSON.stringify(indexes));
            });
        });
    });
    describe('shows', function () {
        describe('doc', function () {
            it('should behave like we expect', function () {
                var showDoc = query.shows.doc;
                assert.equal(fs.readFileSync('./doc/doc_html.html', 'utf-8'), showDoc(doc));
            });
        });
    });
});