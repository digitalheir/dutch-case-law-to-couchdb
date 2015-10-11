var functions = {
        hoge_raad_by_date: {
            map: function (doc) {
                if (doc['creator'] && doc['creator']['@id']) {
                    if (doc['creator']['@id'].match(/Hoge_Raad/)) {
                        var d = new Date(doc['date']);
                        emit(
                            [
                                d.getFullYear(),
                                d.getMonth() + 1,
                                d.getDate()
                            ], 1
                        );
                    }
                }
            },
            reduce: '_count'
        },
        docs_with_rich_markup: {
            map: function (doc) {
                function isMarkedUp(o) {
                    for (var f in o) {
                        if (o.hasOwnProperty(f)) {
                            if (f.match(/section/g)) {
                                return true;
                            } else {
                                if (typeof o[f] == 'object' &&
                                    isMarkedUp(o[f])) {
                                    return true;
                                }
                            }
                        }
                    }
                    return false;
                }

                if (doc.corpus == 'Rechtspraak.nl') {
                    var isMarkedUp = isMarkedUp(doc.simplifiedContent);
                    var d = new Date(doc['date']);
                    emit(
                        [
                            isMarkedUp,
                            d.getFullYear(),
                            d.getMonth() + 1,
                            d.getDate()
                        ], 1
                    );
                    //emit(
                    //    [
                    //        !isMarkedUp,
                    //        d.getFullYear(),
                    //        d.getMonth() + 1,
                    //        d.getDate()
                    //    ], 0
                    //);

                }
            }
            ,
            reduce: "_sum"
        }
    }
    ;

module.exports = functions;