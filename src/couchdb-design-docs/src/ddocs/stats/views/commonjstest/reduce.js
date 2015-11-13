function (keys, values, rereduce) {
    var _ = require('lib/lodash');
    return _.eq({b: 4, a: 2}, {a: 2, b: 4});
}