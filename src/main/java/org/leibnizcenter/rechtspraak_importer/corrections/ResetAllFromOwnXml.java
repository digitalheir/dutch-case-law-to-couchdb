package org.leibnizcenter.rechtspraak_importer.corrections;

import com.cloudant.client.api.CloudantClient;
import com.cloudant.client.api.Database;
import com.cloudant.client.api.model.Response;
import com.cloudant.client.api.views.*;
import com.google.common.util.concurrent.*;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import org.json.JSONArray;
import org.jsoup.HttpStatusException;
import org.leibnizcenter.rechtspraak.CouchDoc;
import org.leibnizcenter.rechtspraak.CouchInterface;
import org.leibnizcenter.rechtspraak.SearchRequest;
import org.leibnizcenter.rechtspraak_importer.*;

import java.io.IOException;
import java.net.SocketException;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

/**
 * Class for importing Dutch case law metadata from http://rechtspraak.cloudant.com/docs .
 *
 * @author Maarten
 */
public class ResetAllFromOwnXml extends RsImporter<Nil> {
    public static void main(String[] args) {
        try {
            new ResetAllFromOwnXml().run();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private final Set<Future> waitingForDocFutures = new HashSet<>(5000);

    public ResetAllFromOwnXml() throws IOException {
        this(1000, -1, 12 * 60 * 60);
    }

    /**
     * @param resultsPerPage How many results per page to load; defaults to the maximum of 1000.
     * @param stopAfter      Number of documents to stop after. Used in debugging; defaults to -1.
     * @param timeOut        Number of seconds to wait on async thread after all search result pages. Defaults to 12 hours
     * @throws IOException
     */
    public ResetAllFromOwnXml(int resultsPerPage, int stopAfter, int timeOut) throws IOException {
        super(resultsPerPage, stopAfter, -1, 4, timeOut);
    }

    public static class Res extends ArrayList<String> {

    }

    @Override
    protected ListeningExecutorService addAllDocsToExecutor() {
        ListeningExecutorService executor = MoreExecutors.listeningDecorator(Executors.newFixedThreadPool(threadNum));


//        AllDocsRequest req = bulkHandler.docsDb.getAllDocsRequestBuilder()
//                .keys(
//                        "ECLI:NL:GHAMS:2002:AF3970",
//                        "ECLI:NL:CRVB:2002:2",
//                        "ECLI:NL:CBB:2010:BM1341",
//                        "ECLI:NL:HR:1984:AC8252").build();


        ViewRequestBuilder b = bulkHandler.docsDb.getViewRequestBuilder("query_dev", "has_simplified_content");
        ViewRequest<Key.ComplexKey, Integer> req = b.newRequest(Key.Type.COMPLEX, Integer.class)
                .reduce(false)
                .build();

        Key.ComplexKeyDeserializer desu = new Key.ComplexKeyDeserializer();
        Gson gson = new GsonBuilder().registerTypeAdapter(Key.ComplexKeyDeserializer.class,
                desu).create();

        try {
            ViewResponse<Key.ComplexKey, Integer> res = req.getResponse();
//            Map<String, String> res = req.getResponse().getIdsAndRevs();
            System.out.println(res.getKeys().size());
            for (Key.ComplexKey e : res.getKeys()) {
                JsonArray json = (JsonArray) desu.serialize(e, null, null);
                String ecli = json.get(0).getAsString();
                String _rev = json.get(1).getAsString();
                //System.out.println(ecli + "; " + _rev);

                addTaskToGetDoc(executor, ecli, _rev);
            }
        } catch (IOException e) {
            throw new Error(e);
        }

        return executor;
    }

    @Override
    protected void handleFailedDocs() {
        int s = getFailed().size();
        if (s > 0)
            System.err.println(s + " failed.");
    }

    private boolean addTaskToGetDoc(ListeningExecutorService executor, final String ecli, final String _rev) {
        final ListenableFuture<Nil> future = executor.submit(new GetDocFromCloudantTask(ecli, _rev, bulkHandler));
        Futures.addCallback(
                future,
                new AddDocToQueueCallback(ecli)
        );
        futures.add(future); //futures is a synchronized set (thread-safe)
        return true;
    }


    public SearchRequest getRequest(int offset) {
        return new SearchRequest.Builder()
                .from(offset)
                .max(resultsPerPage)
                .returnType(SearchRequest.ReturnType.DOC)
                .build();
    }

    public BulkHandler getBulkHandler() {
        return bulkHandler;
    }
}
