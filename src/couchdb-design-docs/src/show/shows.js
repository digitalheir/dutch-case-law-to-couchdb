var functions = {
    show: function (doc, req) {
        if (doc['corpus'] == 'Rechtspraak.nl') {
            var html = "<!DOCTYPE html><html>" +
                "<head><title>" + doc._id + "</title><meta charset=\"UTF-8\"></head>" +
                "<body>" +
                "<table><thead><tr><th>Field</th><th>Value</th></tr></thead><tbody>";
            var url = "https://rechtspraak.cloudant.com/ecli/" + doc._id;
            html += "<tr><td>URL</td><td><a href=\"" + url + "\">" + url + "</a></td></tr>";
            for (var field in doc) {
                if (doc.hasOwnProperty(field) && field != 'simplifiedContent') {
                    var value = doc[field];
                    if (value.hasOwnProperty('@value')) {
                        value = value['@value'];
                    }
                    html += "<tr><td>" + field + "</td><td>" + JSON.stringify(value) + "</td></tr>";
                }
            }
            html += "</tbody></table>" +
                "</body>" +
                "</html>";
            return html;
        }
    }
};

module.exports = functions;