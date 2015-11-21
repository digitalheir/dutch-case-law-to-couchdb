var stringifyFunctions = function (o) {
    if (typeof o == 'function') {
        return o.toString();
    } else if (typeof o == 'object') {
        var map = {};
        for (var functionName in o) {
            if (o.hasOwnProperty(functionName)) {
                map[functionName] = stringifyFunctions(o[functionName]);
            }
        }
        return map;
    } else if (typeof o == 'string') {
        return o;
    } else {
        throw Error(o + '???');
    }
};

module.exports = stringifyFunctions;