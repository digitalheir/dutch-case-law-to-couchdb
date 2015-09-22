function (doc, req) {
    if (doc['corpus'] == 'Rechtspraak.nl') {
        var html = "<html><head><title>" + doc._id + "</title></head><body><table><thead><tr><th>Field</th><th>Value</th></tr></thead><tbody>";
        var url = "https://rechtspraak.cloudant.com/ecli/" + doc._id;
        html += "<tr><td>URL</td><td><a href=\"" + url + "\">" + url + "</a></td></tr>";
        for (var field in doc) {
            html += "<tr><td>" + field + "</td><td>" + JSON.stringify(doc[field]) + "</td></tr>";
        }
        html += "</tbody></table></body></html>";
        return html;
    }
}