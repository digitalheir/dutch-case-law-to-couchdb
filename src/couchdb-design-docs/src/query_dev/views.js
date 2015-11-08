var stringifyFunctions = require('../stringifyFunctions');
var fs = require('fs');


var nat = fs.readFileSync(__dirname+'/natural.js', {encoding: 'utf-8'});
//console.log(nat);

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
    docs_with_section_tag: {
        map: function (doc) {
            function hasSectionTag(o) {
                for (var f in o) {
                    if (o.hasOwnProperty(f)) {
                        if (f.match(/section/g)) {
                            return true;
                        } else {
                            if (typeof o[f] == 'object' &&
                                hasSectionTag(o[f])) {
                                return true;
                            }
                        }
                    }
                }
                return false;
            }

            if (doc.corpus == 'Rechtspraak.nl') {
                var hasSectionTag = hasSectionTag(doc.simplifiedContent);
                var d = new Date(doc['date']);
                emit(
                    [
                        hasSectionTag,
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
    },
    generateCRFTestFile: {
        map: function (doc) {
            var natural = require('views/lib/natural');
            var tokenizer = new natural.WordPunctTokenizer();

            var str = tokenizer.tokenize("Hallo, ik ben een test! :p 33-1:ECLI:30.");
            //if (doc._id.match(/^_/))
            emit(str, str);
        }
    },

    docs_with_image: {
        map: function (doc) {
            function hasAfbeelding(obj) {
                //console.log(obj);
                for (var field in obj) {
                    if (obj.hasOwnProperty(field)) {
                        if (field == 'imageobject') {
                            return true;
                        }
                        var children = obj[field];
                        for (var i = 0; i < children.length; i++) {
                            var child = children[i];
                            if (typeof child == 'object') {
                                if (hasAfbeelding(children[i])) {
                                    return true;
                                }
                            }
                        }
                    }
                }
                return false;
            }

            if (doc.simplifiedContent) {
                //console.log(doc.simplifiedContent)
                //return;
                if (hasAfbeelding(doc.simplifiedContent)) {
                    emit(
                        [
                            doc._id
                        ], 1
                    );
                }
                //emit(
                //    [
                //        !isMarkedUp,
                //        d.getFullYear(),
                //        d.getMonth() + 1,
                //        d.getDate()
                //    ], 0
                //);

            }
        },
        reduce: "_sum"
    },
    "lib": {
        "natural": nat
    }
};

module.exports = functions;