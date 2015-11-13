function (doc) {
    if(doc.corpus=='Rechtspraak.nl'){
        for(var field in doc){
            if(!(field.indexOf('_') === 0 || field == '@context')){
             emit([field, doc._id],1);
            }
        }
    }
}