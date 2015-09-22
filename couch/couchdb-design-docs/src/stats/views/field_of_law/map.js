function (doc) {
    if (doc['dcterms:subject']) {
        for(var i=0;i<doc['dcterms:subject'].length;i++){
            emit([doc['dcterms:subject'][i]['@id']],doc['dcterms:subject'][i]['rdfs:label']);
        }
    }
}