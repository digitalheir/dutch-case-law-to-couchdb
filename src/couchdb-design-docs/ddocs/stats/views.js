var fs = require('fs');

var functions = {
        /**
         * []
         */
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
                         * append all text nodes that are not descendant of <nr>
                         * @param titleElement <title> element
                         */
                        function getTitleString(titleElement) {
                            var strs = [];

                            function recurse(element, arr) {
                                xml.forAllChildren(element, function (childNode) {
                                    if (typeof childNode == 'string') {
                                        arr.push(childNode.trim());
                                    } else {
                                        if (xml.getTagName(element) != 'nr') {
                                            recurse(childNode, arr);
                                        }
                                    }
                                });
                            }

                            recurse(titleElement, strs);
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
                                        return getTitleString(cs[ci])
                                            .trim()
                                            .toLowerCase()
                                            .replace(/^([;:\.]*\s*([0-9]|\b(i{1,3})\b|\b((i?[vx])|([xv]i{0,3}))\b)+\s*[;:\.]*)+\s*/g, '') // Remove leading numbers
                                            .replace(/^(de|het|een)\b\s*/g, '') // Remove leading article
                                            .replace(/[^a-z\s]/ig, '') // remove non-letters
                                            .replace(/\s+/g, ' ') // replace double spaces with single space
                                            .trim()
                                            ;
                                    }
                                }
                            }
                            return null;
                        }

                        var emitRoles = function (node) {
                            xml.forAllChildren(node, function (child) {
                                if (xml.getTagName(child) == 'section') {
                                    var role = child.length > 3 ? getRole(child[3]) : null;
                                    var title = getNormalizedTitle(child); // Title in lowercase, trimmed
                                    emit([role, title], 1);
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
        section_numbers: {
            map: function (doc) {
                var normalizeTitle = function (title) {
                    title = title.trim()
                        .toLowerCase()
                        .replace(/^([;:\.]*\s*([0-9]|\b(i{1,3})\b|\b((i?[vx])|([xv]i{0,3}))\b)+\s*[;:\.]*)+\s*/g, '') // Remove leading numbers
                        .replace(/^(de|het|een)\b\s*/g, '') // Remove leading article
                        .replace(/[^a-z\s]/ig, '') // remove non-letters
                        .replace(/\s+/g, ' ') // replace double spaces with single space
                        .trim()
                    ;
                    return title;
                };
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
                         * append all text nodes that are not descendant of <nr>
                         * @param titleElement <title> element
                         */
                        function getTitleString(titleElement) {
                            var strs = [];

                            function recurse(element, arr) {
                                xml.forAllChildren(element, function (childNode) {
                                    if (typeof childNode == 'string') {
                                        arr.push(childNode.trim());
                                    } else {
                                        if (xml.getTagName(element) != 'nr') {
                                            recurse(childNode, arr);
                                        }
                                    }
                                });
                            }

                            recurse(titleElement, strs);
                            return strs.join(' ');
                        }

                        /**
                         * Tries to find a title node as a direct descendant of given node
                         * @param node
                         */
                        function getTitle(node) {
                            var cs = xml.getChildren(node);
                            if (cs) {
                                for (var ci = 0; ci < cs.length; ci++) {
                                    if (xml.getTagName(cs[ci]) == 'title') {
                                        //Found title
                                        title = getTitleString(cs[ci]);
                                        return title;
                                    }
                                }
                            }
                            return null;
                        }

                        var emitRoles = function (node) {
                            xml.forAllChildren(node, function (child) {
                                if (xml.getTagName(child) == 'section') {
                                    var role = child.length > 3 ? getRole(child[3]) : null;
                                    var title = getTitle(child); // Title in lowercase, trimmed
                                    var number = parseInt(title);
                                    if (!isNaN(number)) {
                                        title = normalizeTitle(title); // Title in lowercase, trimmed
                                        emit([role, number, title], 1);
                                    }
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
        section_title_has_numbering: {
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
                         * append all text nodes that are not descendant of <nr>
                         * @param titleElement <title> element
                         */
                        function getTitleString(titleElement) {
                            var strs = [];

                            function recurse(element, arr) {
                                xml.forAllChildren(element, function (childNode) {
                                    if (typeof childNode == 'string') {
                                        arr.push(childNode.trim());
                                    } else {
                                        if (xml.getTagName(element) != 'nr') {
                                            recurse(childNode, arr);
                                        }
                                    }
                                });
                            }

                            recurse(titleElement, strs);
                            return strs.join(' ');
                        }

                        /**
                         * Tries to find a title node as a direct descendant of given node
                         * @param node
                         */
                        function emitNumbering(node) {
                            var cs = xml.getChildren(node);
                            if (cs) {
                                for (var ci = 0; ci < cs.length; ci++) {
                                    if (xml.getTagName(cs[ci]) == 'title') {
                                        //Found title
                                        var m = getTitleString(cs[ci])
                                            .trim()
                                            .toLowerCase()
                                            .match(/^([;:\.]*\s*([0-9]|\b(i{1,3})\b|\b((i?[vx])|([xv]i{0,3}))\b)+\s*[;:\.]*)+\s*/);
                                        if (m) {
                                            emit([true, m[0].trim().split(' ')], 1);
                                        } else {
                                            emit([false], 1);
                                        }
                                    }
                                }
                            }
                        }

                        var emitHasNumbering = function (node) {
                            xml.forAllChildren(node, function (child) {
                                if (xml.getTagName(child) == 'section') {
                                    emitNumbering(child); // Title in lowercase, trimmed
                                } else {
                                    emitHasNumbering(child);
                                }
                            });
                        };


                        emitHasNumbering(xml.findContentNode(doc.xml));
                    }
                }
            },
            reduce: '_sum'
        },
        section_title_pattern: {
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
                         * append all text nodes that are not descendant of <nr>
                         * @param titleElement <title> element
                         */
                        function getTitleString(titleElement) {
                            var strs = [];

                            function recurse(element, arr) {
                                xml.forAllChildren(element, function (childNode) {
                                    if (typeof childNode == 'string') {
                                        arr.push(childNode.trim());
                                    } else {
                                        if (xml.getTagName(element) != 'nr') {
                                            recurse(childNode, arr);
                                        }
                                    }
                                });
                            }

                            recurse(titleElement, strs);
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
                                        var words = getTitleString(cs[ci])
                                            .trim()
                                            .toLowerCase()
                                            .replace(/^([;:\.]*\s*([0-9]|\b(i{1,3})\b|\b((i?[vx])|([xv]i{0,3}))\b)+\s*[;:\.]*)+\s*/, '') // remove leading numbering
                                            .replace(/[0-9]+/g, ' _NUM ')
                                            .replace(/[“”"‘’]/g, ' _QUOTE ')
                                            .replace(/[\(\)\[\]]/g, ' _BRACKET ')
                                            .replace(/\b[a-zéëèê]+\b/ig, ' _WORD ') // Remove leading article
                                            //.replace(/[^a-zéëèê]+/ig, ' _WORD ') // Remove non-alphanumerics
                                            .trim()
                                            .replace(/\\s+/g, ' ') // compact spaces
                                            .split(' ');
                                        if (words.length == 1 && words[0] == '') {
                                            words = [];
                                        }
                                        return words;
                                    }
                                }
                            }
                            return null;
                        }

                        var emitRoles = function (node) {
                            xml.forAllChildren(node, function (child) {
                                if (xml.getTagName(child) == 'section') {
                                    //var role = child.length > 3 ? getRole(child[3]) : null;
                                    var title = getNormalizedTitle(child); // Title in lowercase, trimmed
                                    emit(title, 1);
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
        /**
         * key: word count
         * value: number of times word count occurs
         */
        // TODO word count for all labels
        word_count_for_title_elements: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                //////////////////
                /**
                 * append all text nodes that are not descendant of <nr>
                 * @param titleElement <title> element
                 */
                function getTitleString(titleElement) {
                    var strs = [];

                    function recurse(element, arr) {
                        xml.forAllChildren(element, function (childNode) {
                            if (typeof childNode == 'string') {
                                arr.push(childNode.trim());
                            } else {
                                if (xml.getTagName(element) != 'nr') {
                                    recurse(childNode, arr);
                                }
                            }
                        });
                    }

                    recurse(titleElement, strs);
                    return strs.join(' ').trim();
                }

                function emitTitleNodeWordCount(node) {
                    var tagName = xml.getTagName(node);
                    if (tagName && tagName.match(/title/i)) {
                        var str = getTitleString(node);
                        emit(str.split(' ').length, 1);
                    } else {
                        xml.forAllChildren(node, emitTitleNodeWordCount);
                    }
                }

                var contentNode = xml.findContentNode(doc.xml, {});

                if (contentNode) {
                    emitTitleNodeWordCount(contentNode);
                }
            },
            reduce: "_count"
        },
        /**
         * key: [<tagname>, <ecli>]
         * value: count
         */
        content_tags: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                //////////////////

                function countElementNames(node, counter) {
                    var tagName = xml.getTagName(node);
                    if (tagName) {
                        if (counter[tagName]) {
                            counter[tagName] = counter[tagName] + 1;
                        } else {
                            counter[tagName] = 1;
                        }
                    }
                    xml.forAllChildren(node, function (chi) {
                        countElementNames(chi, counter);
                    });
                }

                var contentNode = xml.findContentNode(doc.xml, {});

                if (contentNode) {
                    var counter = {};
                    countElementNames(contentNode, counter);
                    for (var field in counter) {
                        if (counter.hasOwnProperty(field)) emit([field, doc._id], counter[field]);
                    }
                }
            },
            reduce: "_sum"
        },
        /**
         * key: [<element name>, <parent name>]
         * value: count
         */
        parent_element_of_element: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                //////////////////

                function emitElementNamesWithParentName(node, parentTag) {
                    if (xml.isElement(node)) {
                        var tagName = xml.getTagName(node);
                        emit([tagName, parentTag], 1);
                        xml.forAllChildren(node, function (chi) {
                            emitElementNamesWithParentName(chi, tagName)
                        });
                    }
                }

                var contentNode = xml.findContentNode(doc.xml);
                if (contentNode) {
                    emitElementNamesWithParentName(contentNode, null);
                }
            },
            reduce: "_sum"
            //,dbcopy: ''
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

                function countTextNodeParents(node, counter) {
                    var tagName = xml.getTagName(node);
                    if (tagName) {
                    }


                    xml.forAllChildren(node, function (chi) {
                        if (typeof chi == 'string') {
                            var txt = chi.trim();
                            if (txt.length > 0) {
                                if (counter[tagName]) {
                                    counter[tagName] = counter[tagName] + 1
                                } else {
                                    counter[tagName] = 1;
                                }
                            }
                        } else {
                            countTextNodeParents(chi, counter);
                        }
                    });
                }

                var contentNode = xml.findContentNode(doc.xml);


                if (contentNode) {
                    var counter = {};
                    countTextNodeParents(contentNode, counter);
                    for (var field in counter) {
                        if (counter.hasOwnProperty(field)) emit([field, doc._id], counter[field]);
                    }
                }
            },
            reduce: "_sum"
            //,dbcopy: ''
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
        title_position_within_section: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                if (doc.xml) {
                    function emitElementPositions(node, pos) {
                        if (xml.getTagName(node) == "section") {
                            pos = 0;
                        } else if (xml.getTagName(node) == "title") {
                            //console.log(node);
                            emit([pos], 1);
                        }
                        xml.forAllChildren(node, function (child) {
                            if (xml.isElement(child)) {
                                if (pos >= 0) { // i.e. this child is in a section
                                    pos++;
                                }
                                emitElementPositions(child, pos);
                            }
                        });
                        return pos;
                    }

                    xml.forAllChildren(xml.findContentNode(doc.xml), function (child) {
                        emitElementPositions(child, -1);
                    });
                }
            },
            reduce: "_sum"
        },
        element_positions: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                if (doc.xml) {
                    function emitElementPositions(node, pos) {
                        if (xml.isElement(node)) {
                            emit([xml.getTagName(node), pos], 1);
                        }
                        xml.forAllChildren(node, function (child) {
                            if (xml.isElement(child)) {
                                pos++;
                                pos = emitElementPositions(child, pos);
                            }
                        });
                        return pos;
                    }

                    xml.forAllChildren(xml.findContentNode(doc.xml), function (child) {
                        emitElementPositions(child, 1);
                    });
                }
            }
            ,
            reduce: "_sum"
        },
        s_p_a_c_e_d__w_o_r_d_s: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }
                if (doc.xml) {
                    function emitSpacedWords(node) {
                        if (typeof node == 'string') {
                            var m = node.match(/\b(?:[A-Z] )+[A-Z]\b/gi);
                            if (m) {
                                //var words = [];
                                for (var i = 0; i < m.length; i++) {
                                    var word = m[i].split(' ').join('');
                                    //words.push(word);
                                    emit([word], 1);
                                }
                            }
                        } else {
                            xml.forAllChildren(node,
                                emitSpacedWords);
                        }
                    }

                    emitSpacedWords(xml.findContentNode(doc.xml));
                }
            },
            reduce: '_sum'
        },
        richness_of_markup: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                if (doc.xml) {
                    var hasInfo = xml.hasTag(doc.xml, /\.info$/);
                    var hasSection = xml.hasTag(doc.xml, "section");

                    var ixBucket = 3;
                    var title = "Contains neither <*.info> tag nor <section> tag";
                    if (hasInfo) {
                        ixBucket = 2;
                        title = "Contains <*.info> tag";
                        if (hasSection) {
                            ixBucket = 0;
                            title += " and <section> tag";
                        }
                    } else {
                        if (hasSection) {
                            ixBucket = 1;
                            title = "Contains only <section> tag";
                        }
                    }
                    // TODO check if sections have titles?

                    var d = new Date(doc['date']);
                    emit([
                            [ixBucket, title],
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
        docs_with_info_tag: {
            map: function (doc) {
                var xml = null;
                try {
                    xml = require('views/lib/xml');
                } catch (err) {
                    xml = require('../xml_util.js');
                }

                if (doc.xml) {
                    var hasS = xml.hasTag(doc.xml, /\.info$/);
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
        lib: {
            "natural": fs.readFileSync('../natural.min.js', {encoding: 'utf-8'}),
            "crfTokenizer": fs.readFileSync('../crf_tokenizer.min.js', {encoding: 'utf-8'}),
            "xml": fs.readFileSync('../xml_util.min.js', {encoding: 'utf-8'})
        }
    }
    ;

module.exports = functions;
