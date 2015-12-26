var fs = require('fs');

var functions = {
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
                        var getRole = function (attrs) {
                            if (attrs) {
                                //console.log('ok3')
                                for (var i = 0; i < attrs.length; i++) {
                                    var key = attrs[i][0];
                                    if (key == 'role') {
                                        return attrs[i][1];
                                    }
                                }
                            }
                            return null;
                        };

                        /**
                         * append all text nodes that are direct descendants (so not the inside of <nr>, for instance)
                         * @param titleElement <title> element
                         */
                        function getTitleString(titleElement) {
                            var strs = [];
                            xml.forAllChildren(titleElement, function (childNode) {
                                if (typeof childNode == 'string') {
                                    strs.push(childNode.trim());
                                }
                            });
                            return strs.join(' ');
                        }

                        /**
                         * Tries to find a title node as a direct descendant of given node
                         * @param node
                         */
                        function getNormalizedTitle(node) {
                            var cs = xml.getChildren(node);
                            if (cs) {
                                for (var ci = 0; ci < cs.length; ci++) {
                                    if (xml.getTagName(cs[ci]) == 'title') {
                                        //Found title
                                        return getTitleString(cs[ci]).trim().toLowerCase();
                                    }
                                }
                            }
                            return null;
                        }

                        var emitRoles = function (node) {
                            xml.forAllChildren(node, function (child) {
                                if (xml.getTagName(child) == 'section') {
                                    var role = child.length > 3 ? getRole(child[3]) : null;
                                    //var title = getNormalizedTitle(child); // Title in lowercase, trimmed
                                    emit([role], 1);
                                } else {
                                    emitRoles(child);
                                }
                            });
                        };


                        emitRoles(xml.findContentNode(doc.xml));
                    }
                }
            },
            reduce: '_sum'
        },
        content_tags: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                //////////////////

                function emitElementNames(node) {
                    var tagName = xml.getTagName(node);
                    if (tagName) {
                        emit([
                                tagName,
                                doc._id
                            ], 1
                        );
                    }
                    xml.forAllChildren(node, function (chi) {
                        emitElementNames(chi);
                    });
                }

                var contentNode = xml.findContentNode(doc.xml);


                if (contentNode) {
                    emitElementNames(contentNode);
                }
            },
            reduce: "_sum"
        },
        parent_elements_of_text: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                //////////////////

                function emitTextNodes(node) {
                    var tagName = xml.getTagName(node);
                    if (tagName) {
                    }
                    xml.forAllChildren(node, function (chi) {
                        if (typeof chi == 'string') {
                            var txt = chi.trim();
                            if (txt.length > 0) {
                                emit([tagName, txt, doc._id], 1)
                            }
                        } else {
                            emitTextNodes(chi);
                        }
                    });
                }

                var contentNode = xml.findContentNode(doc.xml);


                if (contentNode) {
                    emitTextNodes(contentNode);
                }
            },
            reduce: "_sum"
        },
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
        },
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
            },
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