function (doc) {
    if(doc['corpus'] == 'Rechtspraak.nl' && doc['dcterms:creator']){
        emit(doc['dcterms:creator']['@id'],1);
    }
}