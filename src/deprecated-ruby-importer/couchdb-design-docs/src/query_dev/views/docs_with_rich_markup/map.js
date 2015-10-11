function (doc) {
    function isMarkedUp(xml) {
        if (xml.name == 'section') {
            return true;
        } else if (xml.children) {
            for (var i = 0; i < xml.children.length; i++) {
                var child = xml.children[i];
                if (isMarkedUp(child)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    function getUitspraakConclusieTag(xml) {
        var children = xml.children[0].children;
        for (var i = 0; i < children.length; i++) {
            if (children[i].name && children[i].name.match(/conclusie|uitspraak/i)) {
                return children[i];
            }
        }
    }
    
    if (doc.corpus == 'Rechtspraak.nl') {
        if (isMarkedUp(getUitspraakConclusieTag(doc.xml))){
            var date = doc['dcterms:date'];
            var m = date.match(/([0-9]{4})-([0-9]{2})-([0-9]{2})/);
            emit([m[1], m[2], m[3]], 1);
        }
    }
}