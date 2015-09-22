function (doc) {
    if(doc.corpus=='Rechtspraak.nl'){
        emit(doc._id, doc._rev);
    }
}