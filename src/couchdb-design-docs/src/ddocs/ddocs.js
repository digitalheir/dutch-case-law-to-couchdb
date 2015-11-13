var fs = require('fs');

var docs = {
    "docs": [
        require("./show"),
        require("./stats"),
        require("./query"),
        require("./query_dev"),
        require("./crf")
    ]
};

//console.log(docs[3]);

module.exports = docs;