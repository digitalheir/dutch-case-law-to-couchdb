var functions = {
    search: {
        analyzer: "standard",
        index: function (doc) {
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
                } else if (getChildren(node)) {
                    var cs = getChildren(node);
                    for (var i = 0; i < cs.length; i++) {
                        addXmlTxt(cs[i], strings)
                    }
                }
            }

            function getXmlFullText() {
                var strings = [];
                if (doc.xml) {
                    addXmlTxt(doc.xml, strings);
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