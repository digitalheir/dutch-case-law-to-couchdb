function (doc) {
    if(doc.corpus=='Rechtspraak.nl'){
        if(doc.couchDbUpdated){
            var m = doc.couchDbUpdated.match(/^([0-9]{4})-([0-9]{2})-([0-9]{2})/);
            emit([
                    parseInt(m[1],10),
                    parseInt(m[2],10),
                    parseInt(m[3],10)
                ],
                doc._rev);
        }else{
            emit(null,doc._rev);
        }
    }
}