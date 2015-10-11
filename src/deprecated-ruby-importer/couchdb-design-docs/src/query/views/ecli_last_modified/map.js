function (doc) {
    if (doc['corpus'] == 'Rechtspraak.nl' && doc['metadataModified']) {
        emit(doc['_id'], {
            "modified": doc['metadataModified'],
            "_rev": doc['_rev']
        });
    }
}