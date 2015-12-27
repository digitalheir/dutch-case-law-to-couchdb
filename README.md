# Dutch case law as linked open data 

This repository contains code that clones Dutch case law XML documents from 
[data.rechtspraak.nl](http://data.rechtspraak.nl/) and 
converts the metadata to JSON. This makes the documents easier to process with a machine. Because
we store the documents in a [CouchDB](http://couchdb.apache.org/) database, this makes the data instantly amenable to
MapReduce jobs.

Everything described here is a derivative of the [rechtspraak.nl web service](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Pages/default.aspx).
Original documentation is is available in
Dutch [here](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Documents/Technische-documentatie-Open-Data-van-de-Rechtspraak.pdf).

## Document API
Use this API to get Dutch case law documents. Documents are available in XML and HTML.

**XML documents** are retrieved using the URL scheme `https://rechtspraak.cloudant.com/docs/{ECLI identifier}/data.xml`.
[Example](https://rechtspraak.cloudant.com/docs/ECLI:NL:GHSHE:2014:1641/data.xml).

**HTML snippets** are retrieved using the URL scheme `https://rechtspraak.cloudant.com/docs/{ECLI identifier}/data.htm` to
get a HTML snippet. [Example](https://rechtspraak.cloudant.com/docs/ECLI:NL:GHAMS:2013:4606/data.htm).


## Metadata
**Document metadata** is retrieved using the URL scheme `https://rechtspraak.cloudant.com/docs/{ECLI identifier}`.
[Example](https://rechtspraak.cloudant.com/docs/ECLI:NL:GHSHE:2014:1641).

Rechtspraak.nl contains metadata for judgments in XML/RDF, but the RDF is actually not well formed. XML is also arguably [a bad
format for metadata](http://www.programmableweb.com/news/xml-vs.-json-primer/how-to/2013/11/07). In any case,
CouchDB describes documents in JSON, so metadata is converted in JSON. In order to be RDF-compatible, we
ashere to the [JSON-LD](http://json-ld.org/) format.

Also, some additional metadata fields are generated. There are also a
bunch of MapReduce jobs defined on the data. 

<section id="metadata">
    <h3>Metadata format</h3>
    <p>An attempt to correct metadata issues is undertaken in the cloning process. Document metadata is described in
        JSON format, respecting RDF triples through JSON-LD.</p>
    <p>In the following table, all metadata fields are presented, and some guarantees are made about their JSON
        structure. We make some assumptions about the RDF triples that Rechtspraak.nl provides that are not strictly
        necessary, but makes the data easier to work with. Also, some values merit some extra processing in order to
        keep our RDF consistent.</p>
    <p>Some fields are uncommon, so for each field we provide a link to an example document which uses that field. Visit
        <a href="https://rechtspraak.cloudant.com/ecli/_design/query_dev/_view/docs_with_field?limit=10&amp;group_level=2&amp;startkey=[%22dcterms:accessRights%22]&amp;endkey=[%22dcterms:accessRights%22,{}]">ecli/_design/query_dev/_view/docs_with_field?group_level=2&amp;startkey=[&lt;field
            name&gt;&amp; endkey=[&lt;field name&gt;,]</a> to see which documents contain that particular field.</p>
    <h4>Global metadata</h4>
    <p>These fields may appear either in the block for document metadata or the block for register metadata, and we
        assume they are the same in both.</p>
    <table class="bordered-table">
        <thead>
        <tr>
            <th>Tag name / JSON field</th>
            <th>JSON value</th>
            <th>Description</th>
        </tr>
        </thead>
        <tbody>
        <tr>
            <td><code>dcterms:accessRights</code></td>
            <td>String (relative URI)</td>
            <td>Fixed to 'public'. Some manifestations may be non-public, like ones with their names unredacted, but we
                don't have access to those.
            </td>
        </tr>
        <tr>
            <td><code>dcterms:publisher</code></td>
            <td>Object (resource)</td>
            <td>Court. Assumed to be a single object.</td>
        </tr>
        <tr>
            <td><code>dcterms:title</code></td>
            <td>String (literal)</td>
            <td>Document title. Most often, this is a concatenation of the ECLI number with the court name and date.
            </td>
        </tr>
        <tr>
            <td><code>dcterms:language</code></td>
            <td>String (resource URI)</td>
            <td>Fixed to 'nl'.</td>
        </tr>
        <tr>
            <td><code>dcterms:abstract</code></td>
            <td>String (literal)</td>
            <td>Short summary. We do not include abstracts that consist of a single dash, because they are
                uninformative.
            </td>
        </tr>
        <tr>
            <td><code>dcterms:replaces</code></td>
            <td>String (literal)</td>
            <td>LJN number which this ECLI replaces</td>
        </tr>
        <tr>
            <td><code>dcterms:isReplacedBy</code></td>
            <td>String (literal)</td>
            <td>If the current ECLI is not valid, this points to a replacement ECLI. Note this is only about the
                identifier. &lt;a href&gt;Doesn't seem to be used in practice.&lt;/a&gt;</td>
        </tr>
        <tr>
            <td><code>dcterms:contributor</code></td>
            <td>Array of objects ()</td>
            <td>Supposedly denotes the judge. We would like to extend this to also include other entities such as
                lawyers . We may reify these links to denote the roles these people have in the case.&lt;a
                href="https://rechtspraak.cloudant.com/ecli/_design/query_dev/_view/docs_with_field?stale=ok&amp;limit=100&amp;group_level=2&amp;startkey=[%22dcterms:contributor%22]&amp;endkey=[%22dcterms:contributor\ufff0%22]\"&gt;Doesnt
                seem to be used in practice.&lt;/a&gt;</td>
        </tr>
        <tr>
            <td><code>dcterms:date</code></td>
            <td>String (literal)</td>
            <td>Date of judgment</td>
        </tr>
        <tr>
            <td><code>dcterms:alternative</code></td>
            <td>Array of strings (literal)</td>
            <td></td>
        </tr>
        <tr>
            <td><code>psi:procedure</code></td>
            <td>List of objects (resources)</td>
            <td>Aliases / alternative titles. &lt;a
                href="https://rechtspraak.cloudant.com/ecli/_design/query_dev/_view/docs_with_field?stale=ok&amp;limit=100&amp;group_level=1&amp;startkey=[%22dcterms:alternative%22]&amp;endkey=[%22dcterms:alternative\ufff0%22]"&gt;Doesnt
                seem to be used in practice.&lt;/a&gt;</td>
        </tr>
        <tr>
            <td><code>psi:procedure</code></td>
            <td>List of objects (resources)</td>
            <td>What kind of procedure this case is (e.g., 'appeal'). Rechtspraak.nl XML assigns the label 'Procedure'
                to this tag using a &lt;code&gt;rdfs:label&lt;/code&gt; predicate. To fully represent this in RDF, we
                should reify this triple. But to keep our document readable, we assign a JSON-LD alias from &lt;code&gt;Procedure&lt;/code&gt;
                to &lt;code&gt;psi:procedure&lt;/code&gt; in &lt;code&gt;@context&lt;/code&gt;.
            </td>
        </tr>
        <tr>
            <td><code>dcterms:creator</code></td>
            <td>Object (resource)</td>
            <td>Object (resource). Note that we assume a cardinality of 1: behaviour is not defined for multiple&lt;code&gt;dcterms:creator&lt;/code&gt;
                tags. &lt;td&gt;Court in which this judgment was made. &lt;strong&gt;NOTE:&lt;/strong&gt; psi:afdeling
                is deprecated, so we won't parse it &lt;/td&gt;</td>
        </tr>
        <tr>
            <td><code>dcterms:type</code></td>
            <td>Object (resource)</td>
            <td>Represents either 'Uitspraak' or 'Conclusie' ('judgment' or 'conclusion').</td>
        </tr>
        <tr>
            <td><code>dcterms:temporal</code></td>
            <td>Object (resource)</td>
            <td>Indicates a timespan between which the case must be judged, which may happen for example in tax law.
            </td>
        </tr>
        <tr>
            <td><code>dcterms:references</code></td>
            <td>Array of objects (resources)</td>
            <td>These triple have additional data; what &lt;em&gt;kind&lt;/em&gt; of reference is this? These should be
                reified on the triple, but we just add a &lt;code&gt;referenceType&lt;/code&gt;field to the referent
                object.&lt;strong&gt;NOTE:&lt;/strong&gt;Discussed whether this should this references an *expression*
                of a law, because it refers to the law at a particular time (usually the time of the court case). I
                don't resolve the expression because we can't know with full certainty to what time it refers. It's
                rechtspraak.nl's responsibility to get the reference right anyway.
            </td>
        </tr>
        <tr>
            <td><code>dcterms:coverage</code></td>
            <td>Array of objects (resources)</td>
            <td>The jurisdiction to which this judgment is relevant</td>
        </tr>
        <tr>
            <td><code>dcterms:hasVersion</code></td>
            <td>Array of objects (resources)</td>
            <td>Where versions of this judgment can be found. Might be different expressions (e.g., edited and
                annotated)
            </td>
        </tr>
        <tr>
            <td><code>dcterms:relation</code></td>
            <td>Array of objects (reified statements)</td>
            <td>Relations to other cases. &lt;cite&gt;&lt;a
                href="http://dublincore.org/documents/dcmi-terms/#terms-relation"&gt;Dublin Core specification&lt;/a&gt;&lt;/cite&gt;
                specifies: &lt;blockquote&gt; "Recommended best practice is to identify the related resource by means of
                a string conforming to a formal identification system" &lt;/blockquote&gt; &lt;strong&gt;NOTE:&lt;/strong&gt;this
                relation is reified so that we can make meta-statements about it. See &lt;a
                href="http://stackoverflow.com/questions/5671227/ddg#5671407"&gt;stackoverflow.com/questions/5671227/ddg#5671407&lt;/a&gt;.
                This might not follow dcterms best practices.
            </td>
        </tr>
        <tr>
            <td><code>psi:zaaknummer</code></td>
            <td>Array of strings (literal)</td>
            <td>Existing case numbers</td>
        </tr>
        <tr>
            <td><code>dcterms:subject</code></td>
            <td>Array of objects (resource)</td>
            <td>What kind of law this case is about (e.g., 'civil law')</td>
        </tr>
        </tbody>
    </table>

    <h4>Document metadata</h4>
    <table class="bordered-table">
        <thead>
        <tr>
            <th>XML tag name</th>
            <th>JSON field name</th>
            <th>JSON value</th>
            <th>Description</th>
        </tr>
        </thead>
        <tbody>
        <tr>
            <td><code>dcterms:issued</code></td>
            <td></td>
            <td>HTML publication date in YYYY-MM-DD</td>
        </tr>
        <tr>
            <td><code>dcterms:modified</code></td>
            <td></td>
            <td>Document modified</td>
        </tr>
        <tr>
            <td><code>dcterms:identifier</code></td>
            <td></td>
            <td>ECLI id suffixed with :DOC; irrelevant</td>
        </tr>
        <tr>
            <td><code>dcterms:format</code></td>
            <td></td>
            <td>'text/html', irrelevant</td>
        </tr>
        <tr>
            <td><code>htmlIssued</code></td>
            <td>String (YYYY-MM-DD date)</td>
            <td>Date on which this judgment was available on the web. Comes from one of two&lt;code&gt;dcterms:issued&lt;/code&gt;:
                one for the issuing of the original judgment, one for issuing of the web page.
            </td>
        </tr>
        </tbody>
    </table>
    <h3>Register metadata</h3>
    <table class="bordered-table">
        <thead>
        <tr>
            <th>XML tag name</th>
            <th>JSON field name</th>
            <th>JSON value</th>
            <th>Description</th>
        </tr>
        </thead>
        <tbody>
        <tr>
            <td><code>dcterms:format</code></td>
            <td>String</td>
            <td>Doctype: text/xml; this is irrelevant for us.</td>
        </tr>
        <tr>
            <td><code>metadataModified</code></td>
            <td>String (YYYY-MM-DDTh:mm:ss date)</td>
            <td>Date on which the metadata was last modified.</td>
        </tr>
        <tr>
            <td><code>dcterms:modified</code></td>
            <td>String (YYYY-MM-DDTh:mm:ss date)</td>
            <td>Date on which the document was last modified.</td>
        </tr>
        <tr>
            <td><code>dcterms:issues</code></td>
            <td>String</td>
            <td>XML publication date in YYYY-MM-DD.</td>
        </tr>
        </tbody>
    </table>
    <h3>Additional metadata</h3>
    <p>These additional metadata fields are generated by our server.</p>
    <table class="bordered-table">
        <thead>
        <tr>
            <th>JSON field name</th>
            <th>JSON value</th>
            <th>Description</th>
        </tr>
        </thead>
        <tbody>
        <tr>
            <td><code>@type</code></td>
            <td>String (resource URI)</td>
            <td>Fixed to &lt;code&gt;frbr:LegalWork&lt;/code&gt;</td>
        </tr>
        <tr>
            <td><code>markedUpByRechtspraak</code></td>
            <td>Boolean</td>
            <td>Whether this document has rich markup, or consists only of &lt;code&gt;&lt;para&gt;&lt;/code&gt; and
                &lt;code&gt;&lt;paragroup&gt;&lt;/code&gt; elements.
            </td>
        </tr>
        <tr>
            <td><code>owl:sameas</code></td>
            <td>String (resource URI)</td>
            <td>Deeplink to HTML manifestation of this document on &lt;a href="http://www.rechtspraak.nl/"&gt;Rechtspraak.nl&lt;/a&gt;</td>
        </tr>
        <tr>
            <td><code>tokens</code></td>
            <td>Array of arrays of strings</td>
            <td>Tokenized version of judgment text with all XML tags stripped. Stemmed term count is implemented as a
                &lt;a href="#term-frequency"&gt;MapReduce job&lt;/a&gt;.
            </td>
        </tr>
        </tbody>
    </table>
</section>

## Views
A numbers of secondary views are defined on the data set.

--TODO table

