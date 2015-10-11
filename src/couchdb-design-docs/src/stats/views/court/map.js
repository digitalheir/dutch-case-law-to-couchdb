function (doc) {
    if (doc['corpus'] == 'Rechtspraak.nl' && doc['dcterms:creator']) {
        var creator = doc['dcterms:creator'];
        emit([creator['@id']], creator['rdfs:label']);
    }
}