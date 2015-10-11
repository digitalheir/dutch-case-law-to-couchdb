exports.eq = function (a, b) {
    if (a.length != b.length) {
        return false;
    }
    for (var kk1 in a) {
        if (a[kk1] != b[kk1]) {
            return false;
        }
    }
    for (var kk2 in b) {
        if (a[kk2] != b[kk2]) {
            return false;
        }
    }
    return true;
};

exports.uniq = function (a) {
    var out = [];
    for (var i = 0; i < a.length; i++) {
        var contains = false;
        for (var j = 0; j < out.length; j++) {
            if (eq(out[j], a[i])) {
                contains = true;
                break;
            }
        }
        if (!contains) {
            out.push(a[i]);
        }
    }
    return out;
};