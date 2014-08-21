## Rechtspraak to Metalex

This repository contains scripts to get Dutch case law documents from rechtspraak.nl and convert them to a Metalex-compliant form.

## Data extraction from Dutch case law
Although case law documents provided are in XML, a lot of early documents have almost no good markup. They consist merely of `<para>` and `<parablock>` elements (meant for paragraphs and paragraph blocks, respectively). 

But most courts have a way of formatting documents that is very consistent. For example, many verdicts start with a variation of:

    <Court name>
    <Court subdivision>

    U I T S P R A A K
    
    <Subject>
    
    1. Loop van het geding
    
    1. 1 etc.
    
We can use these kinds of patterns to enrich the XML and extract metadata. This repository contains tools and (example) documents to help analysing patterns in these case law documents.
