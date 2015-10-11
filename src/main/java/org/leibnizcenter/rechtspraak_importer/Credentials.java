package org.leibnizcenter.rechtspraak_importer;

/**
 * Credentials for Cloudant
 * <p>
 * Created by maarten on 5-10-15.
 */
public class Credentials {
    public static final String USERNAME = System.getenv("RS_USER");
    public static final String PASSWORD = System.getenv("RS_PASS");
    public static final String COUCH_URL = "http://"+ USERNAME +".cloudant.com";
    public static final String DB_NAME = "docs";
}
