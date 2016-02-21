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


}
