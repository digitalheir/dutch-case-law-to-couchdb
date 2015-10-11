function(doc) {
    if(doc['corpus']=='Rechtspraak.nl'&&doc['dcterms:subject']){
        for(var i=0;i<doc['dcterms:subject'].length;i++){
            var subject_uri = doc['dcterms:subject'][i]['@id'];
            emit(subject_uri,1);
        }
    }
}