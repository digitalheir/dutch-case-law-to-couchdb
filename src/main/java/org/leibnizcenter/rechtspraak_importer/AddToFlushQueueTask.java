package org.leibnizcenter.rechtspraak_importer;

import com.google.common.util.concurrent.Futures;
import org.leibnizcenter.rechtspraak.CouchDoc;

/**
 * Created by maarten on 6-11-15.
 */
public class AddToFlushQueueTask implements java.util.concurrent.Callable<Nil> {
    private final String ecli;
    private final Importer.BulkHandler bulkHandler;

    public AddToFlushQueueTask(String ecli, Importer.BulkHandler bh) {
        this.bulkHandler = bh;
        this.ecli = ecli;
    }

    @Override
    public Nil call() throws Exception {
        bulkHandler.addToBulkQueue(new GetDocTask(ecli).call());
        return null;
    }
}
