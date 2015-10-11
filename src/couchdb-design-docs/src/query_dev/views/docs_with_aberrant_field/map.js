function (doc) {
    for(var field in doc){
        if(field.match(/^[A-Z]/)){
            emit([field,doc._id],1);
        }
    }
}