var functions = {
    search: {
        analyzer: "standard",
        index: function (doc) {
            var xml = null;
            try {
                xml = require('views/lib/xml');
            } catch (err) {
                xml = require('../xml_util.js');
            }

            function indexDate(allWords) {
                if (doc["date"]) {
                    var date = doc["date"];
                    allWords.push(date);

                    var d = new Date(date);

                    index("year", d.getFullYear(), {"store": "yes", "facet": true});
                    index("month", d.getMonth() + 1, {"store": "yes", "facet": true});
                    index("day", d.getDate(), {"store": "yes", "facet": true});

                    indexField("date", "yes", true, []);
                }
            }

            function indexField(fieldName, store, facet, allWords) {
                if (doc[fieldName]) {
                    var strValue = null;
                    var field = doc[fieldName];
                    if (typeof field == "object") {
                        if (field.hasOwnProperty('@value')) {
                            /**
                             * For example abstract['@value']
                             */
                            strValue = field['@value'];
                            allWords.push(field['@value']);
                        } else if (field.push) {
                            /**
                             * Arrays
                             */
                            var values = [];
                            for (var n = 0; n < field.length; n++) {
                                if (field[n]["rdfs:label"]) {
                                    var subject_str = doc["subject"][n]["rdfs:label"][0]["@value"];
                                    values.push(subject_str);
                                    allWords.push(subject_str);
                                }
                            }
                            strValue = values.join(';');
                        }
                    }
                    else if (typeof field == "string") {
                        strValue = field;
                        allWords.push(field);
                    }
                    index(fieldName, strValue, {"store": store, "facet": facet});
                }

            }

            function addXmlTxt(node, strings) {
                if (typeof node == 'string') {
                    if (node.trim().length > 0) {
                        strings.push(node.trim());
                    }
                } else {
                    xml.forAllChildren(node, function (child) {
                        addXmlTxt(child, strings);
                    });
                }
            }

            function getContentNode(node) {
                var n = null;
                xml.forAllChildren(node, function (child) {
                    var tag = xml.getTagName(child);
                    if (tag && tag.match(/uitspraak|conclusie/i)) {
                        n = child;
                    } else {
                        if (!n) {
                            var a = getContentNode(child);
                            if (a) {
                                n = a;
                            }
                        }
                    }
                });
                return n;
            }

            function getXmlFullText() {
                var strings = [];
                if (doc.xml) {
                    var n = getContentNode(doc.xml);
                    addXmlTxt(n, strings);
                }
                return strings.join(" ");
            }

            if (doc['_id'].indexOf("ECLI:") === 0) {
                var globalString = [];
                /*index("replaces", doc["replaces"], {store:"no"})*/
                /* TODO get rdfs label of things like voorlopige voorziening */

                globalString.push(doc._id);
                indexField("subject", "yes", true, globalString);
                indexField("abstract", "yes", false, globalString);
                indexField("title", "yes", false, globalString);
                indexField("ecli", "yes", false, globalString);

                indexDate(globalString);
                index("default", globalString.join(" "), {"store": "no"});
                index("innerText", getXmlFullText(), {"store": "no"});
            }
        }
    }
};

module.exports = functions;