var functions = {
    court: {
        map: function (doc) {
            if (doc['corpus'] == 'Rechtspraak.nl' && doc['creator']) {
                var id = doc['creator']['@id'];
                emit(id, 1);
            }
        }
        ,
        reduce: "_count"
    },
    metadata_modified: {
        map: function (doc) {
            if (doc['corpus'] == 'Rechtspraak.nl') {
                var d = new Date(doc['metadataModified']);
                emit(
                    [
                        d.getFullYear(),
                        d.getMonth() + 1,
                        d.getDate()
                    ],
                    {
                        metadataModified: doc['metadataModified'],
                        contentModified: doc['contentModified'],
                        _rev: doc['_rev']
                    }
                );
            }
        },
        reduce: "_count"
    },
    content_modified: {
        map: function (doc) {
            if (doc['corpus'] == 'Rechtspraak.nl') {
                var d = new Date(doc['contentModified']);
                emit(
                    [
                        d.getFullYear(),
                        d.getMonth() + 1,
                        d.getDate()
                    ],
                    {
                        metadataModified: doc['metadataModified'],
                        contentModified: doc['contentModified'],
                        _rev: doc['_rev']
                    }
                );
            }
        },
        reduce: "_count"
    },
    date: {
        map: function (doc) {
            if (doc['corpus'] == 'Rechtspraak.nl') {
                var d = new Date(doc['date']);
                emit(
                    [
                        d.getFullYear(),
                        d.getMonth() + 1,
                        d.getDate()
                    ], 1
                );
            }
        },
        reduce: "_count"
    },
    field_of_law: {
        map: function (doc) {
            if (doc['corpus'] == 'Rechtspraak.nl' && doc['subject']) {
                for (var i = 0; i < doc['subject'].length; i++) {
                    var subject_uri = doc['subject'][i]['@id'];
                    emit(subject_uri, 1);
                }
            }
        }
        ,
        reduce: "_count"
    }
};

module.exports = functions;