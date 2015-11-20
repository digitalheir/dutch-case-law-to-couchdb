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

            var nodeTypes = {
                1: "element",
                2: "attribute",
                3: "text",
                4: "cdata_section",
                5: "entity_reference",
                6: "entity",
                7: "processing_instruction",
                8: "comment",
                9: "document",
                10: "document_type",
                11: "document_fragment",
                12: "notation"
            };

            var getChildren = function (node) {
                if (nodeTypes[node[0]].match(/element|document/)) {
                    return node[1];
                } else {
                    return undefined;
                }
            };

            var getTagName = function (node) {
                if (nodeTypes[node[0]] == "element") {
                    return node[2];
                } else {
                    return undefined;
                }
            };

            var emitNrParents = function (node) {
                var children = getChildren(node);
                if (children && children.length > 0) {
                    for (var i = 0; i < children.length; i++) {
                        if (getTagName(children[i]) == "nr") {
                            emit([getTagName(node), doc._id], 1);
                        } else {
                            emitNrParents(children[i]);
                        }
                    }
                }
            };

            if (doc.xml) {
                emitNrParents(doc.xml);
            }
        },
        reduce: "_sum"
    },
    words_in_title: {
        map: function (doc) {
            var nodeTypes = {
                1: "element",
                2: "attribute",
                3: "text",
                4: "cdata_section",
                5: "entity_reference",
                6: "entity",
                7: "processing_instruction",
                8: "comment",
                9: "document",
                10: "document_type",
                11: "document_fragment",
                12: "notation"
            };

            var getChildren = function (node) {
                if (nodeTypes[node[0]].match(/element|document/)) {
                    return node[1];
                } else {
                    return undefined;
                }
            };

            var getTagName = function (node) {
                if (nodeTypes[node[0]] == "element") {
                    return node[2];
                } else {
                    return undefined;
                }
            };


            function hasTag(node, tagName) {
                if (getTagName(node) == tagName) {
                    return true;
                } else {
                    var cs = getChildren(node);
                    for (var i = 0; i < cs.length; i++) {
                        if (hasTag(cs[i], tagName)) {
                            return true;
                        }
                    }
                }
                return false;
            }

            function forAllChildren(node, f) {
                var cs = getChildren(node);
                if (cs) {
                    for (var ci = 0; ci < cs.length; ci++) {
                        var child = cs[ci];
                        f(child);
                    }
                }
            }

            if (doc.xml && hasTag(doc.xml, "title")) {
                var nat = null;
                try {
                    nat = require('views/lib/natural');
                } catch (err) {
                    nat = require('natural');
                }
                var tokenizer = new nat.WordPunctTokenizer();

                var emitRecursive = function (node) {
                    if (typeof node == 'string') {
                        var tokens = tokenizer.tokenize(node);
                        for (var i = 0; i < tokens.length; i++) {
                            var token = tokens[i].toLowerCase().trim();
                            emit([token, doc._id], 1);
                        }
                    } else {
                        forAllChildren(node, function (child) {
                            emitRecursive(child);
                        });
                    }
                };

                var emitTitleTokens = function (node) {
                    forAllChildren(node, function (child) {
                        if (getTagName(child) == 'title') {
                            emitRecursive(child);
                        } else {
                            emitTitleTokens(child);
                        }
                    });
                };

                emitTitleTokens(doc.xml);
            }
        },
        reduce: "_sum"
    },
    section_nrs: {
        map: function (doc) {
            var xml = require('views/lib/xml');

            var elementToEmitFrom = 'nr';

            if (xml.hasTag(doc.xml, elementToEmitFrom)) {
                var nat = null;
                try {
                    nat = require('views/lib/natural');
                } catch (err) {
                    nat = require('natural');
                }
                var tokenizer = new nat.WordPunctTokenizer();

                var emitRecursive = function (node) {
                    if (typeof node == 'string') {
                        var tokens = tokenizer.tokenize(node);
                        for (var i = 0; i < tokens.length; i++) {
                            var token = tokens[i].toLowerCase().trim();
                            emit([token, doc._id], 1);
                        }
                    } else {
                        xml.forAllChildren(node, function (child) {
                            emitRecursive(child);
                        });
                    }
                };

                var emitNrTokens = function (node) {
                    xml.forAllChildren(node, function (child) {
                        if (xml.getTagName(node) == elementToEmitFrom) {
                            emitRecursive(node);
                        } else {
                            emitNrTokens(child);
                        }
                    });
                };

                emitNrTokens(doc.xml);
            }
        },
        reduce: "_sum"
    },
    docs_with_section_tag: {
        map: function (doc) {
            var xml = null;
            try {
                require('views/lib/xml');
            } catch (err) {
                require('./xml_util');
            }

            if (doc.xml) {
                var hasS = xml.hasTag(doc.xml, "section");
                var d = new Date(doc['date']);
                emit([
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
    docs_with_image: {
        map: function (doc) {
            var xml = null;
            try {
                require('views/lib/xml');
            } catch (err) {
                require('./xml_util');
            }

            if (doc.xml) {
                var hasS = xml.hasTag(doc.xml, "imageobject");
                emit([
                        hasS,
                        doc._id
                    ], 1
                );
            }
        }
        , reduce: "_sum"
    },
    lib: {
        "natural": fs.readFileSync('./natural.min.js', {encoding: 'utf-8'}),
        "crfTokenizer": fs.readFileSync('./crf_tokenizer.min.js', {encoding: 'utf-8'}),
        "xml": fs.readFileSync('./xml_util.js', {encoding: 'utf-8'})
    }
};

module.exports = functions;