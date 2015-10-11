var functions = {
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
                if (isMarkedUp(doc.simplifiedContent)) {
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
        reduce: "_count"
    }
};

module.exports = functions;