function (doc) {
    if(doc['dcterms:contributor']){
        emit(doc._id, 1);
    }
}