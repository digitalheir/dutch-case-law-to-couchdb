# Dutch case law as linked open data 

This repository contains code that converts Dutch case law documents from data.rechtspraak.nl and convert them to JSON-LD and a [Metalex](http://metalex.eu/)-compliant form.

For a motivation of this project and more high-level description, please go [here](http://leibniz-internship-report.herokuapp.com/#dutch-case-law).

Everything described here is a derivative of the rechtspraak.nl web service. Original documentation is available in Dutch [here](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Documents/Technische-documentatie-Open-Data-van-de-Rechtspraak.pdf).

## Metadata
Metadata in JSON-LD is available at [`http://rechtspraak.lawly.nl/id/{ecli}`](http://rechtspraak.lawly.nl/id/ECLI:NL:RBROT:2014:8730).

## Document API
Use this API to get Dutch case law documents. Documents are available in HTML.

The root URL of this service is at [http://rechtspraak.lawly.nl/](http://rechtspraak.lawly.nl/).

### HTML
Suffix `http://rechtspraak.lawly.nl/ecli/` with an ECLI id and `/data.htm` to get a HTML snipper. [Example](http://rechtspraak.lawly.nl/ecli/ECLI:NL:GHAMS:2013:4606/data.htm).

### Metalex XML
Suffix `http://rechtspraak.lawly.nl/doc/` with an ECLI id to get a Metalex XML manifestation. [Example](http://rechtspraak.lawly.nl/doc/ECLI:NL:GHAMS:2013:4606).

There is one parameter: `return`. 

|parameter|expected value |default|description|Example|
|---------|---------------|-------|-----------|-------|
|return   |`META` or `DOC`|`DOC`  |Whether to return just the metadata for a document (`META`), or metadata along with the document (`DOC`).|[http://dutch-case-law.herokuapp.com/doc/ECLI:NL:CRVB:1999:AA4177?return=META](http://dutch-case-law.herokuapp.com/doc/ECLI:NL:CRVB:1999:AA4177?return=META)|         
 
Metadata is processed considerably; refer to `metadata_handler.rb` to see how different metadata elements are processed.

Note that the Metalex XML markup is not semantic at all. To make the content markup Metalex-compliant, almost all tags are made into inline elements. This is because rechtspraak.nl does not have an existing XML schema, and the XML found is too wild to try and conform to a more descriptive Metalex schema. The original tag names persist in the `name` attribute, however, so no information is lost.
 
