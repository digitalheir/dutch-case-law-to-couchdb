function (doc) {
    var Snowball = require('views/lib/snowball');
    if (doc['corpus'] == 'Rechtspraak.nl' && doc['emit_sections']) {
        for (var i in doc['emit_sections']) {
            for (var j in doc['emit_sections'][i]) {
                var token = doc['emit_sections'][i][j];

                var stemmer = new Snowball('Dutch');
                stemmer.setCurrent(token);
                stemmer.stem();
                emit([stemmer.getCurrent(),  doc['_id']], 1);
            }
        }
    }
}