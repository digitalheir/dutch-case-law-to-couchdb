var stringifyFunctions = require('./../stringifyFunctions');

var term_frequency = {
    views: require('./term_frequency/views')
};

module.exports = {
    "_id": "_design/term_frequency",
    "views": stringifyFunctions(term_frequency.views),
    "lists": {
        term_frequency_in_any_section_title_gt_5: "function(head, req) { " +
        "  send(\"[\");" +
        "  var sent=false;" +
        "  var row; while (row = getRow()) { " +
        "    if(typeof row.key == \"object\" " +
        "&& row.value > 5 && row.key.length > 1){" +
        "      if(sent){send(\",\");}" +
        "      send(JSON.stringify({key:row.key[0],value:row.value}));" +
        "      sent=true;" +
        "    } " +
        "  } " +
        "  send(\"]\");" +
        "}",
        words_in_any_section_title: "function(head, req) { " +
        "  send(\"[\");" +
        "  var sent=false;" +
        "  var row; while (row = getRow()) { " +
        "    if(typeof row.key == \"object\" && row.key.length > 1){" +
        "      if(sent){send(\",\");}" +
        "      send(JSON.stringify({key:row.key[0],value:row.value}));" +
        "      sent=true;" +
        "    } " +
        "  } " +
        "  send(\"]\");" +
        "}",
        words_in_particular_section_title: "function(head, req) { " +
        "  send(\"[\");" +
        "  var sent=false;" +
        "  var row; while (row = getRow()) { " +
        "    if(typeof row.key == \"object\" && row.key.length > 2){" +
        "      if(sent){send(\",\");}" +
        "      send(JSON.stringify({key:[row.key[0],row.key[2]],value:row.value}));" +
        "      sent=true;" +
        "    } " +
        "  } " +
        "  send(\"]\");" +
        "}",
        words_in_particular_section_title_gt_5: "function(head, req) { " +
        "  send(\"[\");" +
        "  var sent=false;" +
        "  var row; while (row = getRow()) { " +
        "    if(typeof row.key == \"object\" " +
        "&& row.value > 5 && row.key.length > 2){" +
        "      if(sent){send(\",\");}" +
        "      send(JSON.stringify({key:[row.key[0],row.key[2]],value:row.value}));" +
        "      sent=true;" +
        "    } " +
        "  } " +
        "  send(\"]\");" +
        "}"
    },
    "rewrites": [],
    "language": "javascript",
    "indexes": {}
};