function (doc) {
    if (doc['dcterms:creator']) {
        if (doc['dcterms:creator']['@id'].match(/Hoge_Raad/)) {
            var date = doc['dcterms:date'];
            var m = date.match(/([0-9]{4})-([0-9]{2})-([0-9]{2})/);
            emit([m[1], m[2], m[3]], 1);
        }
    }
}