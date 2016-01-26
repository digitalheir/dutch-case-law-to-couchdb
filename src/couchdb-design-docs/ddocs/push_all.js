var fs = require('fs');
var push = require('./push_to_couch');

push([
        require("./show"),
        require("./term_frequency"),
        require("./stats"),
        require("./query"),
        require("./query_dev"),
        require("./crf")
    ]
);
