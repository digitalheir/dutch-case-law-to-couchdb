package org.leibnizcenter.rechtspraak_importer;

/**
 * Created by maarten on 6-11-15.
 */
public class AddToFlushQueueTask implements java.util.concurrent.Callable<Nil> {
    private final String ecli;
    private final ImportUnknownFromSearchFeed.BulkHandler bulkHandler;

    public AddToFlushQueueTask(String ecli, ImportUnknownFromSearchFeed.BulkHandler bh) {
        this.bulkHandler = bh;
        this.ecli = ecli;
    }

    @Override
    public Nil call() throws Exception {
        bulkHandler.addToBulkQueue(new GetDocTask(ecli).call());
        return null;
    }
}
