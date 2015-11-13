function (doc) {
    if (doc['dcterms:date']) {
        var m=doc['dcterms:date'].match(/^([0-9]{4})-([0-9]{2})-([0-9]{2})/);
        if(m){
            emit([m[1],m[2],m[3]], 1);
        }
    }
}