function (doc) {
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
    }
}