function (doc) {
    if (doc.ecli && doc._attachments) {
        if (doc._attachments['show.html']) {
            emit(doc.ecli, 1);
        }
    }
}