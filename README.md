# Rechtspraak to Metalex
This repository describes a web service to get Dutch case law documents from data.rechtspraak.nl and convert them to a [Metalex](http://metalex.eu/)-compliant form.

## Document API
Use this API to get Dutch case law documents. Both metadata and markup are converted to the Metalex standard. The root of this service is at [http://dutch-case-law.herokuapp.com/doc/<ecli>](http://dutch-case-law.herokuapp.com/doc/).

There is only one parameter: `return`. 

|parameter|expected value |default|description|
|---------|---------------|-------|-----------|
|return   |`META` or `DOC`|`DOC`  |Whether to return just the metadata for a document (`META`), or metadata along with the document (`DOC`).|         
 
Metadata is processed considerably; refer to `metadata_handler.rb` to see how different metadata elements are processed.

To make the content markup Metalex-compliant, almost all tags are made into inline elements. This is because rechtspraak.nl does not have an existing XML schema, and the XML found is too wild to try and conform to a more descriptive Metalex schema. The original tag names persist in the `name` attribute, though, so no information is lost.

### Examples 
[http://dutch-case-law.herokuapp.com/doc/ECLI:NL:CRVB:1999:AA4177](http://dutch-case-law.herokuapp.com/doc/ECLI:NL:CRVB:1999:AA4177)

Will return a full document with metadata


[http://dutch-case-law.herokuapp.com/doc/ECLI:NL:CRVB:1999:AA4177?return=META](http://dutch-case-law.herokuapp.com/doc/ECLI:NL:CRVB:1999:AA4177?return=META)

Will return only metadata for a given ECLI
 
## Search API
Rechtspraak.nl has an Atom-based (XML) search API. Because JSON is usually a litle bit easier to work with, here's a JSON wrapper around this API.

The root URL is [http://dutch-case-law.herokuapp.com/search](http://dutch-case-law.herokuapp.com/search). Use the following parameters to filter:

|parameter|expected value |default|description|
|---------|---------------|-------|-----------|
|return   |`META` or `DOC`|`DOC`  |Whether to return the cases for which we at least have metadata (`META`), or for which we also have the document (`DOC`).|         
|max     |Int between 1 and 1000, inclusive|1000|The maximum number of documents to return|
|from     |Int, at least 0|0      |The numbers of documents to skip|
|sort     |`ASC` or `DESC`|`ASC`  |Which direction to sort the documents (sorted on modification date)|
|replaces |An LJN string  |       |Returns documents that correspond to the antiquated LJN identifier|
|date     |1 or 2 dates formatted `YYYY-MM-DD`||**NOTE: Not in use.** If 1 date is specified, returns only cases for that day. If 2 dates are provided, returns cases between those dates.|
|modified |1 or 2 dates formatted `YYYY-MM-DD`||**NOTE: Not in use.** Same as date, but for document changes|
|type     |`Uitspraak` or `Conclusie`||Which type of case to return, default both|
|subject  |URI            |       |Return only cases for given legal subject|
|creator  |String         |       |Return only cases for given judicial body|
                           
### Examples:
[http://dutch-case-law.herokuapp.com/search?max=100&from=0&return=META](http://dutch-case-law.herokuapp.com/search?max=100&from=0&return=META)

Gives back the first page of cases that rechtspraak has at least metadata for.


[http://dutch-case-law.herokuapp.com/search?max=100&from=0&return=DOC](http://dutch-case-law.herokuapp.com/search?max=100&from=0&return=DOC)

And this for cases for which documents are available.

                          