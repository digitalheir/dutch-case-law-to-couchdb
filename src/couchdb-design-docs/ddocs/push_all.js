var fs = require('fs');
var push = require('./push_to_couch');

push([
        require("./show"),
        require("./stats"),
        require("./query"),
        require("./query_dev"),
        require("./crf")
    ]
);
