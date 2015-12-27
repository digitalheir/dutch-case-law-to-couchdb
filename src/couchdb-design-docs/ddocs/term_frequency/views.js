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
                    var natural = null;
                    try {
                        natural = require('views/lib/natural');
                    } catch (err) {
                        natural = require('../natural.js');
                    }
                    var tokenizer = new natural.WordPunctTokenizer();

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
                                        return getTitleString(cs[ci]).trim().toLowerCase()
                                            .replace(/[0-9]+/g, '_NUM')
                                            .replace(/\b(i{1,3})\b/g, '_NUM') // i, iii, iii
                                            .replace(/\b((i?[vx])|([xv]i{0,3}))\b/g, '_NUM')// iv, v, vi, vii, viii,ix,x,xi,xii,xiii
                                            .replace(/\s\s+/g, ' ') // replace double spaces with single space
                                            .replace(/^\s*(_NUM\s*)+\s*[;:\.]+/g, '_NUM .') // Add space between first num and period/colon
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
                                    emit([role, title, doc._id], 1);
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
