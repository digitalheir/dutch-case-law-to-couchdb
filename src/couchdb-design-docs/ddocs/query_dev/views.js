var fs = require('fs');

//console.log(nat);

var functions = {
    random: {
        map: function (doc) {
            emit(doc._rev.match(/^\d+-(\w+)$/)[1], 1);
        }
    },
    hoge_raad_by_date: {
        map: function (doc) {
            if (doc['creator'] && doc['creator']['@id']) {
                if (doc['creator']['@id'].match(/Hoge_Raad/)) {
                    var d = new Date(doc['date']);
                    emit(
                        [
                            d.getFullYear(),
                            d.getMonth() + 1,
                            d.getDate()
                        ], 1
                    );
                }
            }
        },
        reduce: '_count'
    },
    has_simplified_content: {
        map: function (doc) {
            if (doc.simplifiedContent) {
                emit([doc._id, doc._rev], 1
                );
            }
        },
        reduce: '_count'
    },
    document_fields: {
        map: function (doc) {
            if (doc.corpus == 'Rechtspraak.nl') {
                for (var field in doc) {
                    if (doc.hasOwnProperty(field)) {
                        emit([field, doc._id], 1);
                    }
                }
            }
        },
        reduce: "_sum"
    }
};

module.exports = functions;