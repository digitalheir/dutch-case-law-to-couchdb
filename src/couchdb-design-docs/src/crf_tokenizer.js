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

module.exports = {
    /**
     *
     * @param tokenizer
     * @param content object with arbitrarily deeply nested strings, keyed by their tag name
     */
    tokenize: function (tokenizer, content) {
        if (!tokenizer) {
            throw new Error("Tokenizer should exist");
        }
        var tokens = [];

        //var tokens = tokenizer.tokenize(doc.simplifiedContent);
        //var str = tokenizer.tokenize("Hallo, ik ben een test! :p 33-1:ECLI:30.");

        for (var tagName in content) {
            if (content.hasOwnProperty(tagName)) {
                var o = content[tagName];
                if (typeof o == 'string') {
                    var stringTokens = tokenizer.tokenize(o);
                    for (var tokenI = 0; tokenI < stringTokens.length; tokenI++) {
                        var str = stringTokens[tokenI];
                        tokens.push({
                            "string": str,
                            "tag": tagName,
                            "isPeriod": !!str.match(/^[\.]+$/),
                            "isNumber": !!str.match(/^[0-9\.]+$/),
                            "isCapitalized": !!str.match(/^[A-Z]/) //Match uppercase character
                        });
                    }
                } else if (isArrayLike(o)) {
                    for (var i = 0; i < o.length; i++) {
                        var ob = {};
                        ob[tagName] = o[i];
                        tokens.push.apply(tokens, this.tokenize(tokenizer, ob));
                    }
                } else {
                    tokens.push.apply(tokens, this.tokenize(tokenizer, o));
                }
            }
        }
        return tokens;
    }
};