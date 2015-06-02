# Dutch case law as linked open data 

This repository contains code that clones Dutch case law XML documents from 
[data.rechtspraak.nl](http://data.rechtspraak.nl/) and 
converts the metadata to JSON-LD. This makes the documents easier to process with a machine.

Everything described here is a derivative of the [rechtspraak.nl web service](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Pages/default.aspx). Original documentation is available in 
Dutch [here](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Documents/Technische-documentatie-Open-Data-van-de-Rechtspraak.pdf).

## Metadata
**Document metadata** is retrieved using the URL scheme `https://rechtspraak.cloudant.com/ecli/{ECLI identifier}`.
[Example](https://rechtspraak.cloudant.com/ecli/ECLI:NL:GHSHE:2014:1641/data.xml).

Rechtspraak.nl contains metadata for judgments in XML/RDF, but the RDF is actually not well formed. XML is also [a bad 
format for metadata](http://www.programmableweb.com/news/xml-vs.-json-primer/how-to/2013/11/07) (I think). In any case, 
CouchDB describes documents in JSON, so metadata is converted into well-formed [JSON-LD](http://json-ld.org/) format to 
be RDF-compatible.

Also, some additional metadata fields are generated, like a tokenized version of the judgment text. There are also a 
bunch of MapReduce jobs defined on the data. 

--TODO metadata table

## Views
A numbers of secondary views are defined on the data set. Most prominently, we perform an unrefined term frequency 
count. 

--TODO table

## Document API
Use this API to get Dutch case law documents. Documents are available in XML and HTML.

**XML documents** are retrieved using the URL scheme `https://rechtspraak.cloudant.com/ecli/{ECLI identifier}/data.xml`.
[Example](https://rechtspraak.cloudant.com/ecli/ECLI:NL:GHSHE:2014:1641/data.xml).

**HTML snippets** are retrieved using the URL scheme `http://rechtspraak.lawly.nl/ecli/{ECLI identifier}/data.htm` to 
get a HTML snippet. [Example](http://rechtspraak.lawly.nl/ecli/ECLI:NL:GHAMS:2013:4606/data.htm).
 
 
## Prerequisites
* [Ruby](https://www.ruby-lang.org/) (tested on 2.1.6) plus dependencies that are written down in `Gemfile`
* [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/AlpinoUserGuide.html) plus all dependencies. This projects assumes 
environment variable `ALPINO_HOME` to be set, e.g. `export ALPINO_HOME=/home/username/Alpino`. Alpino is a mess of Perl, 
C, and shell scripts. If you rather not use it, you can comment out the lines using it in `rechtspraak_expression.rb`, 
or just let the tokenization fail silently. 