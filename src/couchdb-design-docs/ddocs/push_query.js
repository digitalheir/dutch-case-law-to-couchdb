var push = require('./push_to_couch');
var ddoc = require("./query.js");

push([
        ddoc
    ]
);
