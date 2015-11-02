# Dutch case law as linked open data 

This repository contains code that clones Dutch case law XML documents from 
[data.rechtspraak.nl](http://data.rechtspraak.nl/) and 
converts the metadata to JSON. This makes the documents easier to process with a machine. Because
we store the documents in a [CouchDB](http://couchdb.apache.org/) database, this makes the data instantly amenable to
MapReduce jobs.

Everything described here is a derivative of the [rechtspraak.nl web service](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Pages/default.aspx).
Original documentation is is available in
Dutch [here](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Documents/Technische-documentatie-Open-Data-van-de-Rechtspraak.pdf).

## Metadata
**Document metadata** is retrieved using the URL scheme `https://rechtspraak.cloudant.com/docs/{ECLI identifier}`.
[Example](https://rechtspraak.cloudant.com/docs/ECLI:NL:GHSHE:2014:1641).

Rechtspraak.nl contains metadata for judgments in XML/RDF, but the RDF is actually not well formed. XML is also arguably [a bad
format for metadata](http://www.programmableweb.com/news/xml-vs.-json-primer/how-to/2013/11/07). In any case,
CouchDB describes documents in JSON, so metadata is converted in JSON. In order to be RDF-compatible, we
ashere to the [JSON-LD](http://json-ld.org/) format.

Also, some additional metadata fields are generated. There are also a
bunch of MapReduce jobs defined on the data. 

--TODO metadata table

## Views
A numbers of secondary views are defined on the data set.

--TODO table

## Document API
Use this API to get Dutch case law documents. Documents are available in XML and HTML.

**XML documents** are retrieved using the URL scheme `https://rechtspraak.cloudant.com/docs/{ECLI identifier}/data.xml`.
[Example](https://rechtspraak.cloudant.com/docs/ECLI:NL:GHSHE:2014:1641/data.xml).

**HTML snippets** are retrieved using the URL scheme `https://rechtspraak.cloudant.com/docs/{ECLI identifier}/data.htm` to
get a HTML snippet. [Example](https://rechtspraak.cloudant.com/docs/ECLI:NL:GHAMS:2013:4606/data.htm).
