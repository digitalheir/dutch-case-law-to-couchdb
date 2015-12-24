var fs = require('fs');
var push = require('./push_to_couch');
var secret = require('./../secret');
var PouchDB = require('pouchdb');

var word_count_title = new PouchDB("http://" + secret.username + ".cloudant.com/word_count_title", {
    auth: secret
});

var word_count_nr = new PouchDB("http://" + secret.username + ".cloudant.com/word_count_nr", {
    auth: secret
});


var string_count_title = new PouchDB("http://" + secret.username + ".cloudant.com/string_count_title", {
    auth: secret
});

var string_count_nr = new PouchDB("http://" + secret.username + ".cloudant.com/string_count_nr", {
    auth: secret
});


var ddoc = {
    "_id": "_design/ddoc",
    "views": {
        sort_by_count: {map: "function(doc){emit(doc.value,doc.key);}"}
    },
    "rewrites": [],
    "language": "javascript"
};

push([
    ddoc
    ], word_count_title
);

push([
ddoc
    ], word_count_nr
);

push([
        ddoc
    ], string_count_title
);

push([
        ddoc
    ], string_count_nr
);