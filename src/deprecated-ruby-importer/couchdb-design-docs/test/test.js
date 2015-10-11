var assert = require("assert");
var doc = require("./doc/doc");
var fs = require("fs");
var doc_search_index = require("./doc/doc_search_index");


describe('query', function () {
    describe('indexes', function () {
        describe('search', function () {
            var indexes = {};
            var index = function (fieldName, strValue, options) {
                indexes[fieldName] = [strValue, options];
            };
            var search = function (doc) {
    function indexDate(allWords) {
        if (doc["dcterms:date"]) {
            var date = doc["dcterms:date"];
            allWords.push(date);
            var m = date.match(/^([0-9]{4})-([0-9]{2})-([0-9]{2})/);
            index("year", m[1], {"store": "yes", "facet": true});
            index("month", m[2], {"store": "yes", "facet": true});
            index("day", m[3], {"store": "yes", "facet": true});
            indexField("dcterms:date", "yes", true, []);
        }
    }

    function indexField(fieldName, store, facet, allWords) {
        if (doc[fieldName]) {
            var strValue = null;
            var field = doc[fieldName];
            if (typeof field == "object" && field.push && true) {
                /**
                 * Arrays
                 */

                var values = [];
                for (var n = 0; n < field.length; n++) {
                    if (field[n]["rdfs:label"]) {
                        var subject_str = doc["dcterms:subject"][n]["rdfs:label"][0]["@value"];
                        values.push(subject_str);
                        allWords.push(subject_str);
                    }
                }
                strValue = values.join(';');
            } else if (typeof field == "string") {
                strValue = field;
                allWords.push(field);
            }
            index(fieldName, strValue, {"store": store, "facet": facet});
        }

    }

    function addXmlTxt(root, strings) {
        if (root.type == 'text') {
            if (root.content.trim().length > 0) {
                strings.push(root.content.trim());
            }
        }

        if (root && root.children) {
            for (var i = 0; i < root.children.length; i++) {
                addXmlTxt(root.children[i], strings);
            }
        }
    }

    function getUitspraakConclusieTag(xml) {
        var children = xml.children[0].children;
        for (var i = 0; i < children.length; i++) {
            if (children[i].name && children[i].name.match(/conclusie|uitspraak/i)) {
                return children[i];
            }
        }
    }

    function getXmlFullText() {
        var strings = [];
        var root = getUitspraakConclusieTag(doc.xml);
        addXmlTxt(root, strings);
        return strings.join(" ");
    }

    if (doc['_id'].indexOf("ECLI:") === 0) {
        var globalString = [];
        /*index("dcterms:replaces", doc["dcterms:replaces"], {store:"no"})*/
        /* TODO get rdfs label of things like voorlopige voorziening */

        globalString.push(doc._id);
        indexField("dcterms:subject", "yes", true, globalString);
        indexField("dcterms:abstract", "yes", false, globalString);
        indexField("dcterms:title", "yes", false, globalString);
        indexField("ecli", "yes", false, globalString);

        indexDate(globalString);
        index("default", globalString.join(" "), {"store": "no"});

        index("innerText", getXmlFullText(), {"store": "no"});
    }
};
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
                var showDoc = function (doc, req) {
    if (doc['corpus'] == 'Rechtspraak.nl') {
        var html = "<html><head><title>" + doc._id + "</title></head><body><table><thead><tr><th>Field</th><th>Value</th></tr></thead><tbody>";
        var url = "https://rechtspraak.cloudant.com/ecli/" + doc._id;
        html += "<tr><td>URL</td><td><a href=\"" + url + "\">" + url + "</a></td></tr>";
        for (var field in doc) {
            if (field != 'xml') {
                html += "<tr><td>" + field + "</td><td>" + JSON.stringify(doc[field]) + "</td></tr>";
            }
        }
        html += "</tbody></table></body></html>";
        return html;
    }
};
                assert.equal(fs.readFileSync('./doc/doc_html.html', 'utf-8'), showDoc(doc));
            });
        });
    });
});
describe('query_dev', function () {
    describe('views', function () {
        describe('docs_with_nonpara_markup', function () {
            describe('map', function () {
                var emitted = [];
                var emit = function (key, val) {
                    emitted.push([key, val])
                };
                var f = function (doc) {
    function isMarkedUp(xml) {
        if (xml.name != 'para'
            || xml.name != 'parablock'
            || xml.name != 'paragroup'
        ) {
            return true;
        } else if (xml.children) {
            for (var i = 0; i < xml.children.length; i++) {
                var child = xml.children[i];
                if (isMarkedUp(child)) {
                    return true;
                }
            }
        }
        return false;
    }

    function getUitspraakConclusieTag(xml) {
        var children = xml.children[0].children;
        for (var i = 0; i < children.length; i++) {
            if (children[i].name && children[i].name.match(/conclusie|uitspraak/i)) {
                return children[i];
            }
        }
    }
    
    if (doc.corpus == 'Rechtspraak.nl') {
        if (isMarkedUp(getUitspraakConclusieTag(doc.xml))) {
            var date = doc['dcterms:date'];
            var m = date.match(/([0-9]{4})-([0-9]{2})-([0-9]{2})/);
            emit([m[1], m[2], m[3]], 1);
        }
    }
};
                f(doc);
                it('should behave like we expect', function () {
                    assert.equal(JSON.stringify(emitted), JSON.stringify([[['2003', '09', '12'], 1]]));
                });
            });
        });
        describe('docs_with_rich_markup', function () {
            describe('map', function () {
                var emitted = [];
                var emit = function (key, val) {
                    emitted.push([key, val])
                };
                var f = function (doc) {
    function isMarkedUp(xml) {
        if (xml.name == 'section') {
            return true;
        } else if (xml.children) {
            for (var i = 0; i < xml.children.length; i++) {
                var child = xml.children[i];
                if (isMarkedUp(child)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    function getUitspraakConclusieTag(xml) {
        var children = xml.children[0].children;
        for (var i = 0; i < children.length; i++) {
            if (children[i].name && children[i].name.match(/conclusie|uitspraak/i)) {
                return children[i];
            }
        }
    }
    
    if (doc.corpus == 'Rechtspraak.nl') {
        if (isMarkedUp(getUitspraakConclusieTag(doc.xml))){
            var date = doc['dcterms:date'];
            var m = date.match(/([0-9]{4})-([0-9]{2})-([0-9]{2})/);
            emit([m[1], m[2], m[3]], 1);
        }
    }
};
                f(doc);
                console.log(emitted);
                it('should behave like we expect', function () {
                    assert.equal(emitted.length, 0);
                });
            });
        });
    });
});
