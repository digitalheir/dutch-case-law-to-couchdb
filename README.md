Data extraction from Dutch case law
===================================

Rechtspraak.nl provides access to historical Dutch case law through an [API](http://www.rechtspraak.nl/Uitspraken-en-Registers/Uitspraken/Open-Data/Pages/default.aspx). 

Although the documents provided are in XML, a lot of early documents are basically just prose. They consist merely of `<para>` and `<parablock>` elements, denoting paragraphs and paragraph blocks. 

But most courts have a way of formatting documents that is very consistent. For example, many verdicts start with a variation of the header

    <Court name>
    <Court subdivision>

    U I T S P R A A K
    
    <Subject>
    
    1. Loop van het geding
    
    1. 1 etc.
    
We can use these patterns to enrich the XML and extract metadata. This repository contains tools and (example) documents to help analysing patterns in these case law documents.
