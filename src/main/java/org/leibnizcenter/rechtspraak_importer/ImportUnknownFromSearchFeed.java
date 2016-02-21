package org.leibnizcenter.rechtspraak_importer;

import com.google.common.collect.ImmutableMap;
import com.google.common.collect.Lists;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import com.google.common.util.concurrent.ListeningExecutorService;
import com.google.common.util.concurrent.MoreExecutors;
import org.leibnizcenter.rechtspraak.SearchRequest;
import org.leibnizcenter.rechtspraak_importer.model.CouchDoc;
import org.xml.sax.SAXException;

import javax.xml.parsers.ParserConfigurationException;
import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;

/**
 * Class for importing Dutch case law metadata from http://www.rechtspraak.nl .
 *
 * @author Maarten
 */
public class ImportUnknownFromSearchFeed extends RsImporter<Nil> {

    final Map<String, String> existingDocRevs;

    public ImportUnknownFromSearchFeed() throws IOException {
        super();
        this.existingDocRevs = ImmutableMap.copyOf(
                bulkHandler.docsDb.getAllDocsRequestBuilder()
                        .startKey("ECLI")
                        .endKey("D")
                        .build()
                        .getResponse()
                        .getIdsAndRevs()
        );
        System.out.println("Found " + existingDocRevs.size() + " already imported docs.");
    }

    public ImportUnknownFromSearchFeed(int resultsPerPage, int startAt, int stopAfter, int threadNum, int timeOut) throws IOException {
        super(resultsPerPage, startAt, stopAfter, threadNum, timeOut);
        this.existingDocRevs = ImmutableMap.copyOf(
                bulkHandler.docsDb.getAllDocsRequestBuilder()
                        .startKey("ECLI")
                        .endKey("D")
                        .build()
                        .getResponse()
                        .getIdsAndRevs()
        );
        System.out.println("Found " + existingDocRevs.size() + " already imported docs.");
    }


    public ListeningExecutorService addAllDocsToExecutor() {
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

    @Override
    protected void handleFailedDocs() {
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
    }

    private List<String> getEclisForOffset(int offset) throws IOException, ParserConfigurationException, SAXException {
        List<SearchRequest.JudgmentMetadata> entries = getRequest(offset).execute();
        return Lists.transform(entries, judgmentMetadata -> judgmentMetadata.id);
    }

    boolean alreadyHaveDoc(String id) {
        return existingDocRevs.get(id) != null;
    }

    private boolean addTaskToGetDoc(ListeningExecutorService executor, final String ecli) {
        // start tasks to convert JudgmentMetadata to the LegalObject subclass Judgment
        if (!alreadyHaveDoc(ecli)) {

            final ListenableFuture<Nil> future = executor.submit(
                    new AddToFlushQueueTask(ecli, bulkHandler)
            );
            Futures.addCallback(
                    future,
                    new AddDocToQueueCallback(ecli)
            );
            futures.add(future); //futures is a synchronized set (thread-safe)
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

    public static void main(String[] args) {
        System.out.println("Starting importer service");
        ImportUnknownFromSearchFeed i = null;
        try {
            i = new ImportUnknownFromSearchFeed();
            i.run();
        } catch (IOException e) {
            throw new Error(e);
        }
    }
}
