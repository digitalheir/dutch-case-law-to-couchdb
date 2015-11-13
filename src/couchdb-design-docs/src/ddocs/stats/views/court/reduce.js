function (keys, values, rereduce) {
    var eq = function (a, b) {
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
    var uniq = function (a) {
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
    if (rereduce) {
        var fmap = {count:0, labels:[]};
        for (var subMapI in values) {
            var subMap = values[subMapI];
            fmap.count += subMap.count;
            fmap.labels = uniq(subMap.labels.concat(fmap.labels));
        }
        return fmap;
    } else {
        var map = {count:0, labels:[]};
        for (var i = 0; i < values.length; i++) {
            var val = values[i];
            map.labels = uniq(map.labels.concat(val));
            map.count += 1;
        }
        return map;
    }
}