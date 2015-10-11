package org.leibnizcenter.rechtspraak_importer;

import org.leibnizcenter.rechtspraak_importer.Importer;

import java.io.IOException;
import java.util.concurrent.Executor;

/**
 * Created by Maarten on 29/09/2015.
 */
public class Import implements Executor {
    public void execute(Runnable command) {
        command.run();
    }

    public static void main(String[] args) {
        System.out.println("Starting importer service");
        Importer i = null;
        try {
            i = new Importer();
            i.run();
        } catch (IOException e) {
            throw new Error(e);
        }
    }
}
