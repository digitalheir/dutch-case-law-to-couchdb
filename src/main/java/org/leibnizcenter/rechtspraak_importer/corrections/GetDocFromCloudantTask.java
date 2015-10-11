package org.leibnizcenter.rechtspraak_importer.corrections;

import com.squareup.okhttp.HttpUrl;
import com.squareup.okhttp.Response;
import generated.OpenRechtspraak;
import org.leibnizcenter.rechtspraak.*;
import org.leibnizcenter.rechtspraak_importer.Credentials;

import javax.xml.bind.JAXBException;
import javax.xml.xpath.XPathExpressionException;
import java.io.IOException;
import java.net.URI;

/**
 * Retrieve document from Cloudant; downloads the original XML and creates a new CouchDoc. Used when something has
 * gone wrong in the Cloudant database and we need te reset our docs from original XML.
 *
 * Created by maarten on 5-10-15.
 */
public class GetDocFromCloudantTask implements java.util.concurrent.Callable<CouchDoc> {
    private final String ecli;

    public GetDocFromCloudantTask(String ecli) {
        this.ecli = ecli;
    }

    public static Response request(String ecli) throws IOException, JAXBException, XPathExpressionException {
        URI uri = URI.create(getXmlUrl(ecli));
        HttpUrl url = HttpUrl.get(uri);
        return new DocumentRequest(url).execute();
    }

    public static String getXmlUrl(String ecli) {
        return Credentials.COUCH_URL + "/"+Credentials.DB_NAME+"/" + ecli + "/data.xml";
    }


    @Override
    public CouchDoc call() throws Exception {
        com.squareup.okhttp.Response res = CouchInterface.request(ecli.trim());
        String strXml = res.body().string();
        OpenRechtspraak or = RechtspraakNlInterface.parseXml(strXml);
        return new CouchDoc(or, strXml);
    }
}
