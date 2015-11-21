var assert = require('assert');
var xml = require('../xml_util');


describe('cml_utils', function () {
    it('should loop over children', function () {
        var i = 0;
        var child = [];
        xml.forAllChildren([1, [child]], function (n) {
            i++;
            assert.equal(n, child);
        });
        assert.equal(i, 1);
    });
});