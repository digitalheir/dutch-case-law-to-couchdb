
var push = require('./push_to_couch');

push([
        require("./term_frequency")
    ], 'string_blocks'
);
