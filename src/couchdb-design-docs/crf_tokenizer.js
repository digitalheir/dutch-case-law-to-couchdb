var property = function (key) {
    return function (obj) {
        return obj == null ? void 0 : obj[key];
    };
};
var MAX_ARRAY_INDEX = Math.pow(2, 53) - 1;
var getLength = property('length');
var isArrayLike = function (collection) {
    var length = getLength(collection);
    return typeof length == 'number' && length >= 0 && length <= MAX_ARRAY_INDEX;
};

var nodeTypes = {
    1: "element",
    2: "attribute",
    3: "text",
    4: "cdata_section",
    5: "entity_reference",
    6: "entity",
    7: "processing_instruction",
    8: "comment",
    9: "document",
    10: "document_type",
    11: "document_fragment",
    12: "notation"
};
var getChildren = function (node) {
    if (nodeTypes[node[0]].match(/element|document/)) {
        return node[1];
    } else {
        return undefined;
    }
};

var getTagName = function (node) {
    if (nodeTypes[node[0]] == "element") {
        return node[2];
    } else {
        return undefined;
    }
};


module.exports = {
    /**
     *
     * @param tokenizer
     * @param content object with arbitrarily deeply nested strings
     */
    tokenize: function (tokenizer, content) {

        function recursivelyTokenize(node) {
            var tokenObjs = [];
            var children = getChildren(node);
            if (children) {
                for (var i = 0; i < children.length; i++) {
                    var child = children[i];
                    if (typeof child == "string") {
                        var tokens = tokenizer.tokenize(child);
                        for (var t = 0; t < tokens.length; t++) {
                            var str = tokens[t];
                            var tokenObj = ({
                                "string": str,
                                "tag": getTagName(node),
                                "isPeriod": !!str.match(/^[\.]+$/),
                                "isNumber": !!str.match(/^[0-9\.]+$/),
                                "isCapitalized": !!str.match(/^[A-Z]/) //Match uppercase character
                            });
                            tokenObjs.push(tokenObj);
                        }
                    } else {
                        tokenObjs.push.apply(tokenObjs, recursivelyTokenize(child));
                    }
                }
            }
            return tokens;
        }

        if (!tokenizer) {
            throw new Error("Tokenizer should exist");
        }
        //var str = tokenizer.tokenize("Hallo, ik ben een test! :p 33-1:ECLI:30.");
        return recursivelyTokenize(content);
    }
};