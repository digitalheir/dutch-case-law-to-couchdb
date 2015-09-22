function (doc) {
    var Snowball = require('views/lib/snowball');
    if (doc['corpus'] == 'Rechtspraak.nl' && doc['tokens']) {
        for (var i in doc['tokens']) {
            for (var j in doc['tokens'][i]) {
                var token = doc['tokens'][i][j];

                var stemmer = new Snowball('Dutch');
                stemmer.setCurrent(token);
                stemmer.stem();
                emit([stemmer.getCurrent(),  doc['_id']], 1);
            }
        }
    }
}