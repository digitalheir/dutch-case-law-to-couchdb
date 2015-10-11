package org.leibnizcenter.rechtspraak_importer;

import generated.OpenRechtspraak;
import org.leibnizcenter.rechtspraak.CouchDoc;
import org.leibnizcenter.rechtspraak.RechtspraakNlInterface;

/**
 * Retrieves the document with given ecli from Rechtspraak.nl and transforms it into a
 * {@link CouchDoc} for serialization to JSON in a CouchDB.
 * <p>
 * Created by maarten on 5-10-15.
 */
public class GetDocTask implements java.util.concurrent.Callable<CouchDoc> {
    private final String ecli;

    public GetDocTask(String ecli) {
        this.ecli = ecli;
    }

    @Override
    public CouchDoc call() throws Exception {
        com.squareup.okhttp.Response res = RechtspraakNlInterface.requestXmlForEcli(ecli);
        String strXml = res.body().string();
        OpenRechtspraak or = RechtspraakNlInterface.parseXml(strXml);
        return new CouchDoc(or, strXml);
    }
}
