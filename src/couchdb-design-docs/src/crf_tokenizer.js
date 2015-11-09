module.exports = {
    /**
     *
     * @param tokenizer
     * @param content object with arbitrarily deeply nested strings, keyed by their tag name
     */
    tokenize: function (tokenizer, content) {
        var tokens = [];

        //var tokens = tokenizer.tokenize(doc.simplifiedContent);
        //var str = tokenizer.tokenize("Hallo, ik ben een test! :p 33-1:ECLI:30.");

        for (var tagName in content) {
            if (content.hasOwnProperty(tagName)) {
                var o = content[tagName];
                if (typeof o == 'string') {
                    var stringTokens = tokenizer.tokenize(o);
                    for (var tokenI; tokenI < stringTokens.length; tokenI++) {
                        var str = stringTokens[tokenI];
                        tokens.push({
                            "tag": tagName,
                            "isNumber": !!str.match(/[0-9\.]+/),
                            "isCapitalized": !!str.match(/^\p{Lu}/) //Match uppercase character
                        });
                    }
                } else {
                    tokens.push.apply(tokens, this.tokenize(o));
                }
            }
        }
        return tokens;
    }
};