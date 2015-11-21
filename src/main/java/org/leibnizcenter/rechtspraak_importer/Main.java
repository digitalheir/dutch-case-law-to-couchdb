package org.leibnizcenter.rechtspraak_importer;

import java.io.IOException;
import java.util.concurrent.Executor;

/**
 * Created by Maarten on 29/09/2015.
 */
public class Main implements Executor {
    public void execute(Runnable command) {
        command.run();
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
