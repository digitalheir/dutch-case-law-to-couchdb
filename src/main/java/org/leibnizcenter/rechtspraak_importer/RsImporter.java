package org.leibnizcenter.rechtspraak_importer;

import com.cloudant.client.api.CloudantClient;
import com.cloudant.client.api.Database;
import com.cloudant.client.api.model.Response;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListeningExecutorService;
import org.jsoup.HttpStatusException;
import org.leibnizcenter.rechtspraak.CouchInterface;
import org.leibnizcenter.rechtspraak_importer.model.CouchDoc;

import java.io.IOException;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Created by Maarten on 21-11-2015.
 */
public abstract class RsImporter<T> implements Runnable {
    public final int stopAfter;
    /**
     * Maximum number of results to return from search interface
     */
    public final int resultsPerPage;
    public final int timeOut;
    /**
     * Arbitrary number of threads
     */
    protected final int threadNum;
    protected final BulkHandler bulkHandler;
    protected final List<ListenableFuture<T>> futures = Collections.synchronizedList(new ArrayList<>(5000));
    final List<String> failed = Collections.synchronizedList(new ArrayList<>());
    final int startAt;

    public RsImporter() throws IOException {
        this(1000, 0 /*+ 300 * 1000*/, -1, 16, 12 * 60 * 60);
    }

    /**
     * @param resultsPerPage How many results per page to load; defaults to the maximum of 1000.
     * @param startAt        Number of documents to offset start. Used in debugging primarily; defaults to 0.
     * @param stopAfter      Number of documents to stop after. Used in debugging primarily; defaults to -1.
     * @param timeOut        Number of seconds to wait on async thread after all search result pages. Defaults to 12 hours
     * @throws IOException
     */
    public RsImporter(int resultsPerPage, int startAt, int stopAfter, int threadNum, int timeOut) throws IOException {
        this.resultsPerPage = resultsPerPage;
        this.stopAfter = stopAfter;
        this.timeOut = timeOut;
        this.startAt = startAt;
        this.threadNum = threadNum;

        this.bulkHandler = new BulkHandler();
    }

    @Override
    public void run() {
        failed.clear();
        ListeningExecutorService executor = addAllDocsToExecutor();

        performTasks(executor);
    }

    protected abstract ListeningExecutorService addAllDocsToExecutor();


    public void performTasks(ListeningExecutorService executor) {
        ListenableFuture<List<T>> resultsFuture = Futures.allAsList(futures);

        // Wait for threads to finish
        System.out.println("Awaiting all tasks to finish...");
        try {
            resultsFuture.get(timeOut, TimeUnit.SECONDS);
        } catch (InterruptedException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
        }
        try {
            executor.shutdown();
            executor.awaitTermination(timeOut, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }

        handleFailedDocs();


        // Now that we know all threads have either finished or timed out, commit the final flush in case some documents are still in the queue
        bulkHandler.flush();
        System.out.println("Done!");
    }

    protected abstract void handleFailedDocs();

    public List<ListenableFuture<T>> getFutures() {
        return futures;
    }

    public int getTimeOut() {
        return timeOut;
    }

    public List<String> getFailed() {
        return failed;
    }

    public BulkHandler getBulkHandler() {
        return bulkHandler;
    }


    public class BulkHandler {

        private static final int MAX_BULK_SIZE = 500;
        public final List<CouchDoc> addToBulkQueue = Collections.synchronizedList(new ArrayList<>(500));
        public final Database docsDb;
        private final CloudantClient client;
        private int sizeKb;
        private int maxSizeMb = 10;

        public BulkHandler() throws IOException {
            String username = Credentials.USERNAME;
            String password = Credentials.PASSWORD;

            this.client = new CloudantClient(username, username, password);
            this.docsDb = client.database(Credentials.DB_NAME, true);
        }


        public void addToBulkQueue(CouchDoc judgment) {
            ArrayList<CouchDoc> toFlush = null;

            synchronized (addToBulkQueue) {
                addToBulkQueue.add(judgment);
                sizeKb += getKiloByteSize(judgment);

//                System.out.println("Adding " + judgment._id + " (" + (sizeKb / 1024) + " MB)");
//                System.out.println("Adding " + addToBulkQueue.size() + " (" + (sizeKb / 1024) + " MB)");

                if (addToBulkQueue.size() >= MAX_BULK_SIZE
                        || sizeKb >= (maxSizeMb * 1024)
                        ) {
                    toFlush = new ArrayList<>(addToBulkQueue);
                    System.out.println("Flushing " + toFlush.size() + " docs (" + (sizeKb / 1024) + " MB) on thread " + Thread.currentThread().getId());
                    clear();
                }
            }

            if (toFlush != null) {
                bulk(toFlush);
            }
        }

        private void clear() {
            addToBulkQueue.clear();
            sizeKb = 0;
        }

        private void bulk(final List<CouchDoc> toFlush) {
            List<Response> responses = docsDb.bulk(toFlush);
            responses.stream().filter(res -> res.getError() != null).forEach(
                    res -> System.err.println(res.getId() + ": " + res.getError())
            );
            System.out.println("Flushed " + toFlush.size() + " docs; " /*+
                    "still got " + futures.size() + " docs in the waiting list"*/);
        }

        private int getKiloByteSize(CouchDoc judgment) {
            return CouchInterface.toJson(judgment).getBytes().length / 1024;
        }

        public void flush() {
            synchronized (addToBulkQueue) {
                ArrayList<CouchDoc> toFlush = new ArrayList<>(addToBulkQueue);
                clear();
                bulk(toFlush);
            }
        }
    }

    protected class AddDocToQueueCallback implements FutureCallback<T> {
        //        private final ListenableFuture<CouchDoc> future;
        private final String ecli;

        public AddDocToQueueCallback(String ecli) {
//            this.future = future;
            this.ecli = ecli;
        }

        @Override
        public void onSuccess(T judgment) {
            //waitingOnFutures.remove(future); //waitingOnFutures is a synchronized set (thread-safe)
        }


        @Override
        public void onFailure(Throwable throwable) {
            //waitingOnFutures.remove(future); //#waitingOnFutures is a synchronized set (thread-safe)
            failed.add(ecli);//#failed is a synchronized set (thread-safe)

            System.err.println("Error downloading " + ecli + ": " + throwable.getMessage());
            if (!(throwable instanceof HttpStatusException
                    || throwable instanceof SocketException
                    || "Document should have exactly one uitspraak or conclusie".equals(throwable.getMessage())
            )) {
                throwable.printStackTrace();
            }
        }
    }
}
