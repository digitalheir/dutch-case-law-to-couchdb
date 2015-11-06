package org.leibnizcenter.rechtspraak_importer;

import com.cloudant.client.api.CloudantClient;
import com.cloudant.client.api.Database;
import com.cloudant.client.api.model.Response;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Lists;
import com.google.common.util.concurrent.*;
import org.jsoup.HttpStatusException;
import org.leibnizcenter.rechtspraak.CouchDoc;
import org.leibnizcenter.rechtspraak.CouchInterface;
import org.leibnizcenter.rechtspraak.SearchRequest;
import org.xml.sax.SAXException;

import javax.xml.parsers.ParserConfigurationException;
import java.io.IOException;
import java.net.SocketException;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

/**
 * Class for importing Dutch case law metadata from http://www.rechtspraak.nl .
 *
 * @author Maarten
 */
public class Importer implements Runnable {
    public final List<String> failed = Collections.synchronizedList(new ArrayList<>());


    private final int stopAfter;
    /**
     * Maximum number of results to return from search interface
     */
    private final int resultsPerPage;
    private final int startAt;

    /**
     * Arbitrary number of threads
     */
    private final int threadNum;
    private final int timeOut;


    private final BulkHandler bulkHandler;
    private final Set<Future> waitingOnFutures = Collections.synchronizedSet(new HashSet<>(5000));

    public Importer() throws IOException {
        this(1000, 0, -1, 32, 12 * 60 * 60);
    }

    /**
     * @param resultsPerPage How many results per page to load; defaults to the maximum of 1000.
     * @param startAt        Number of documents to offset start. Used in debugging primarily; defaults to 0.
     * @param stopAfter      Number of documents to stop after. Used in debugging primarily; defaults to -1.
     * @param timeOut        Number of seconds to wait on async thread after all search result pages. Defaults to 12 hours
     * @throws IOException
     */
    public Importer(int resultsPerPage, int startAt, int stopAfter, int threadNum, int timeOut) throws IOException {
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

        // Wait for threads to finish
        executor.shutdown();
        try {
            System.out.println("Awaiting all threads to finish...");
            executor.awaitTermination(timeOut, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }


        // If there are some docs that failed before, try and handle them synchronously
        if (failed.size() > 0) {
            System.out.println("Retrying " + failed.size() + " doc(s) that failed before");
            synchronized (failed) { // Should not be necessary to synchronize, because this is the only thread running at this point
                for (String ecliFailed : failed) {
                    try {
                        CouchDoc doc = new GetDocTask(ecliFailed).call();
                        bulkHandler.addToBulkQueue(doc);
                    } catch (Exception e) {
                        if ("Document should have exactly one uitspraak or conclusie".equals(e.getMessage())) {
                            System.err.println(ecliFailed + ": " + e.getMessage());
                        } else {
                            e.printStackTrace();
                        }
                    }
                }
            }
        }


        // Now that we know all threads have either finished or timed out, commit the final flush in case some documents are still in the queue
        bulkHandler.flush();
        System.out.println("Done!");
    }

    private ListeningExecutorService addAllDocsToExecutor() {
        ListeningExecutorService executor = MoreExecutors.listeningDecorator(Executors.newFixedThreadPool(threadNum));
        boolean reachedEndOfSearch = false;

        int offset = startAt;
        do {
            try {
                int newDocsCount = 0;
                List<String> eclis = getEclisForOffset(offset);
                offset += resultsPerPage;
                for (final String ecli : eclis) {
                    boolean added = addTaskToGetDoc(executor, ecli);
                    if (added) {
                        newDocsCount++;
                    }
                }
                if (newDocsCount != resultsPerPage) {
                    System.out.println("Found " + newDocsCount + " new documents on page " + ((offset / resultsPerPage)) + "");
                }
                reachedEndOfSearch = eclis.size() < resultsPerPage // We know we've reached (past) the final page when it contains < resultsPerPage results
                        || (stopAfter > 0 && offset > stopAfter);
            } catch (NullPointerException e) {
                //TODO remove
                System.err.println("Should not happen");
                e.printStackTrace();
                reachedEndOfSearch = false;
            } catch (IOException e) {
                // If an error is thrown here, we try the next page.
                e.printStackTrace();
                reachedEndOfSearch = false;
            } catch (ParserConfigurationException | SAXException e) {
                // If an error is thrown here, we lose our main thread and stop running through search results
                // pages. Any running thread is not terminated, however.
                throw new Error(e);
            }
        } while (!reachedEndOfSearch);
        return executor;
    }

    private List<String> getEclisForOffset(int offset) throws IOException, ParserConfigurationException, SAXException {
        List<SearchRequest.JudgmentMetadata> entries = getRequest(offset).execute();
        return Lists.transform(entries, judgmentMetadata -> judgmentMetadata.id);
    }

    private boolean addTaskToGetDoc(ListeningExecutorService executor, final String ecli) {
        // start tasks to convert JudgmentMetadata to the LegalObject subclass Judgment
        if (!bulkHandler.alreadyHaveDoc(ecli)) {
            final ListenableFuture<CouchDoc> future = executor.submit(new GetDocTask(ecli));
            waitingOnFutures.add(future); //waitingOnFutures is a synchronized set (thread-safe)
            Futures.addCallback(
                    future,
                    new CouchDocFutureCallback(future, ecli)
            );
            return true;
        } else {
            return false;
        }
    }


    public SearchRequest getRequest(int offset) {
        return new SearchRequest.Builder()
                .from(offset)
                .max(resultsPerPage)
                .returnType(SearchRequest.ReturnType.DOC)
                .build();
    }


    private class BulkHandler {
        private static final int MAX_BULK_SIZE = 500;
        private final Map<String, String> existingDocRevs;
        private int sizeKb;
        private int maxSizeMb = 50;
        private final List<CouchDoc> addToBulkQueue = Collections.synchronizedList(new ArrayList<>(500));

        private final CloudantClient client;
        private final Database docsDb;

        public BulkHandler() throws IOException {
            String username = Credentials.USERNAME;
            String password = Credentials.PASSWORD;

            this.client = new CloudantClient(username, username, password);
            this.docsDb = client.database(Credentials.DB_NAME, true);


            existingDocRevs = ImmutableMap.copyOf(
                    docsDb.getAllDocsRequestBuilder()
                            .startKey("ECLI")
                            .endKey("D")
                            .build()
                            .getResponse()
                            .getIdsAndRevs()
            );
            System.out.println("Found " + existingDocRevs.size() + " already imported docs.");
        }

        private boolean alreadyHaveDoc(String id) {
            return existingDocRevs.get(id) != null;
        }

        private void addToBulkQueue(CouchDoc judgment) {
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
            System.out.println("Flushed " + toFlush.size() + " docs; " +
                    "still got " + waitingOnFutures.size() + " docs in the waiting list");
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

    private class CouchDocFutureCallback implements FutureCallback<CouchDoc> {
        private final ListenableFuture<CouchDoc> future;
        private final String ecli;

        public CouchDocFutureCallback(ListenableFuture<CouchDoc> future, String ecli) {
            this.future = future;
            this.ecli = ecli;
        }

        @Override
        public void onSuccess(CouchDoc judgment) {
            waitingOnFutures.remove(future); //waitingOnFutures is a synchronized set (thread-safe)
            bulkHandler.addToBulkQueue(judgment);
        }


        @Override
        public void onFailure(Throwable throwable) {
            waitingOnFutures.remove(future); //#waitingOnFutures is a synchronized set (thread-safe)
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
