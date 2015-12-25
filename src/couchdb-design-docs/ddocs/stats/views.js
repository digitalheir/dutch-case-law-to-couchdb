var fs = require('fs');

var functions = {
        parents_of_nr: {
            map: function (doc) {
                //var property = function (key) {
                //    return function (obj) {
                //        return obj == null ? void 0 : obj[key];
                //    };
                //};
                //var MAX_ARRAY_INDEX = Math.pow(2, 53) - 1;
                //var getLength = property('length');
                //var isArrayLike = function (collection) {
                //    var length = getLength(collection);
                //    return typeof length == 'number' && length >= 0 && length <= MAX_ARRAY_INDEX;
                //};


                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }
                function emitNrParents(node) {
                    xml.forAllChildren(node, function (child) {
                        if (xml.getTagName(child) == 'nr') {
                            emit([xml.getTagName(node), doc._id], 1);
                        }

                        emitNrParents(child);
                    });
                }

                if (doc.xml) {
                    emitNrParents(doc.xml);
                }
            },
            reduce: "_sum"
        },
        words_in_title: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }
                if (doc.xml && xml.hasTag(doc.xml, "title")) {
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
                                var token = tokens[i].toLowerCase().replace(/\s/g, '');
                                if (token.length > 0) {
                                    emit(token, 1);//Don't emit whitespace
                                }
                            }
                        } else {
                            if (xml.getTagName(node) != 'nr') {
                                xml.forAllChildren(node, function (child) {
                                    emitRecursive(child);
                                });
                            }
                        }
                    };

                    var emitTitleTokens = function (node) {
                        xml.forAllChildren(node, function (child) {
                            if (xml.getTagName(child) == 'title') {
                                emitRecursive(child);
                            } else {
                                emitTitleTokens(child);
                            }
                        });
                    };

                    emitTitleTokens(doc.xml);
                }
            },
            reduce: "_sum",
            dbcopy: "word_count_title"
        },
        section_nrs: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

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
                                var token = tokens[i].toLowerCase().replace(/\s/g, '');
                                if (token.length > 0) {
                                    emit(token, 1);//Don't emit whitespace
                                }
                            }
                        } else {
                            xml.forAllChildren(node, function (child) {
                                emitRecursive(child);
                            });
                        }
                    };

                    var emitNrTokens = function (node) {
                        xml.forAllChildren(node, function (child) {
                            if (xml.getTagName(child) == elementToEmitFrom) {
                                emitRecursive(child);
                            } else {
                                emitNrTokens(child);
                            }
                        });
                    };

                    emitNrTokens(doc.xml);
                }
            },
            reduce: "_sum",
            dbcopy: "word_count_nr"
        },
        section_roles: {
            map: function (doc) {
                if (doc.xml) {
                    var xml = null;
                    try {
                        xml = require('views/lib/xml');
                    } catch (err) {
                        xml = require('../xml_util.js');
                    }
                    //console.log('ok1')
                    var elementToEmitFrom = 'section';

                    if (xml.hasTag(doc.xml, elementToEmitFrom)) {
                        //console.log('ok2')
                        var emitRole = function (attrs) {
                            if (attrs) {
                                //console.log('ok3')
                                for (var i = 0; i < attrs.length; i++) {
                                    var key = attrs[i][0];
                                    if (key == 'role') {
                                        var val = attrs[i][1];
                                        emit([val, doc._id], 1);
                                    }
                                }
                            }
                        };
                        var emitRoles = function (node) {
                            xml.forAllChildren(node, function (child) {
                                if (xml.getTagName(child) == 'section') {
                                    emitRole(child[3]);
                                } else {
                                    emitRoles(child);
                                }
                            });
                        };


                        emitRoles(xml.findContentNode(doc.xml));
                    }
                }
            },
            reduce: 'count'
        },
        section_titles_full: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                var elementToEmitFrom = 'title';

                if (xml.hasTag(doc.xml, elementToEmitFrom)) {
                    var emitRecursive = function (node) {
                        if (typeof node == 'string') {
                            var normalized = node.trim().toLowerCase();
                            if (normalized.length > 0)
                                emit([normalized, doc._id], 1);//Don't emit whitespace
                        } else {
                            if (xml.getTagName(node) != 'nr') { // Ignore nr tag

                                xml.forAllChildren(node, function (child) {
                                    emitRecursive(child);
                                });
                            }
                        }
                    };

                    var startEmit = function (node) {
                        if (xml.getTagName(node) == elementToEmitFrom) {
                            emitRecursive(node);
                        } else {
                            xml.forAllChildren(node, function (child) {
                                    startEmit(child);
                                }
                            );
                        }
                    };

                    startEmit(doc.xml);
                }
            },
            reduce: "_sum",
            dbcopy: "string_count_title"
        },
        section_nrs_full: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                var elementToEmitFrom = 'nr';

                if (xml.hasTag(doc.xml, elementToEmitFrom)) {
                    var emitRecursive = function (node) {
                        if (typeof node == 'string') {
                            var normalized = node.trim().toLowerCase();
                            if (normalized.length > 0)
                                emit([normalized, doc._id], 1);//Don't emit whitespace
                        } else {
                            xml.forAllChildren(node, function (child) {
                                emitRecursive(child);
                            });
                        }
                    };

                    var emitNrText = function (node) {
                        xml.forAllChildren(node, function (child) {
                            if (xml.getTagName(child) == elementToEmitFrom) {
                                emitRecursive(child);
                            } else {
                                emitNrText(child);
                            }
                        });
                    };

                    emitNrText(doc.xml);
                }
            }
            ,
            reduce: "_sum",
            dbcopy: "string_count_nr"
        }
        ,
        docs_with_section_tag: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
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
            ,
            reduce: "_sum"
        }
        ,
        docs_with_image: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
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
            ,
            reduce: "_sum"
        }
        ,
        lib: {
            "natural": fs.readFileSync('../natural.min.js', {encoding: 'utf-8'}),
            "crfTokenizer": fs.readFileSync('../crf_tokenizer.min.js', {encoding: 'utf-8'}),
            "xml": fs.readFileSync('../xml_util.min.js', {encoding: 'utf-8'})
        }
    }
    ;

module.exports = functions;