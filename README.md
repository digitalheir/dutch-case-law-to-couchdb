# Rechtspraak to Metalex

This repository contains scripts to get Dutch case law documents from data.rechtspraak.nl and convert them to a Metalex-compliant form.

## Metalex conversion
Both metadata and markup are converted to the Metalex standard. 

Metadata is processed considerably; refer the appendix to see how different metadata elements are processed.

To make the content markup Metalex-compliant, almost all tags are made into inline elements. This is because rechtspraak.nl does not have an existing XML schema, and the XML found is too wild to try and conform to a more descriptive Metalex schema. The original tag names persist in the `name` attribute, though, so no information is lost.

## Search API
Rechtspraak.nl has an Atom-based (XML) search API. Because JSON is usually a litle bit easier to work with, we made a JSON wrapper around this API.

The root URL is [http://dutch-case-law.herokuapp.com/search](http://dutch-case-law.herokuapp.com/search). Use the following parameters to filter:

|parameter|expected value |default|description                    |
|---------|---------------|-------|-------------------------------|
|return   |`META` or `DOC`|`DOC`  |Whether to return the cases for|  
|         |               |       |which we at least have metadata| 
|         |               |       |(`META`), or for which we also |
|         |               |       |have the document (`DOC`).     |