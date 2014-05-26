# Gerechtshof te Amsterdam


```regex
/gerechtshof te amsterdam\s*(kenmerk.?.?\s*([^\s]+))\s*(^\s.*)U/i
```

Examples:

```  
      Gerechtshof te Amsterdam
      
      kenmerk: P96/2906
      
      GERECHTSHOF TE AMSTERDAM
      
      Tweede Meervoudige Belastingkamer
      
      UITSPRAAK
```
([ECLI:NL:GHAMS:1997:AA4418](1997/AA4418.xml))
	  
```
      Gerechtshof te Amsterdam
        Kenmerk: P95/5210	GERECHTSHOF TE AMSTERDAM
        	Derde Meervoudige Belastingkamer  
        	UITSPRAAK
```
([ECLI:NL:GHAMS:1997:AA4145](1997/AA4145.xml))
	  

	  
We can't make assumptions about tags and whitespacing but GHAMS has very consistent prose for
- Court name
- local identifier 
- subsection of the court (belastingkamer). This information is not available as metadata!
- Where the verdict starts

# Case subject

```
      op het beroep van de besloten vennootschap X B.V. te Z, belanghebbende,
      
      tegen
      
      een uitspraak van het Hoofd Douane P, de inspecteur.
```
([ECLI:NL:GHAMS:1997:AA4418](1997/AA4418.xml))

```
         	Uitspraak van het Gerechtshof te Leeuwarden, 
         	vierde enkelvoudige belastingkamer, op het
         	beroep van X te Z tegen de door de belastingdienst ondernemingen te P (:de inspecteur) opgelegde aanslag wegens navordering van inkomstenbelasting voor het jaar 1988.
```	
([ECLI:NL:GHAMS:1997:AA4145](1997/AA4145.xml))  

The subject of the case is harder to extract. We know that:
- It is after the start of the verdict ('UITSPRAAK') and before the the first header ('1. Loop van het geding')

It may be possible to extract redacted names. They are single uppercase letters like X, Z, P, and sometimes a number of asterisks (*). Need to test precision.

```
      1. Loop van het geding
```
([ECLI:NL:GHAMS:1997:AA4418](1997/AA4418.xml))
([ECLI:NL:GHAMS:1997:AA4145](1997/AA4145.xml))

Other headers:

```
      2. Tussen partijen vaststaande feiten
      3. Geschil
      4. Standpunten van partijen
      5. Beoordeling van het geschil
      6. Proceskosten
```
([ECLI:NL:GHAMS:1997:AA4418](1997/AA4418.xml))    

Is similar to 

```
   2. Tussen partijen vaststaande feiten
      3. Geschil
      4. Standpunten van partijen
      5. Beoordeling van het geschil
      6. Proceskosten
```
([ECLI:NL:GHAMS:1997:AA4145](1997/AA4145.xml))

Note that we can't just look for something that starts with a number and a period:

```
	    "2.	Verliezen en vermissen. 
        3.	Salderen van meer- en minderbevindingen
```
([ECLI:NL:GHAMS:1997:AA4418](1997/AA4418.xml))    

## Verdict
	  
	  BESLISSING
      Het Hof bevestigt de uitspraak waarvan beroep.
      
      De uitspraak is vastgesteld op 11 december 1997 door mrs. Bijl, voorzitter, Boersma en Simons, leden van de belastingkamer, in tegenwoordigheid van mr. Visser als griffier. De beslissing is op die datum ter openbare zitting uitgesproken. 
      
      De voorzitter van de belastingkamer heeft geen bezwaar tegen afgifte door de griffier van de uitspraak in geanonimiseerde vorm.
      
     
    
	
	   7. Beslissing
      
      Het Hof bevestigt de bestreden uitspraak.
      
      
      
        De uitspraak is vastgesteld op 7 mei 1997 door Mrs. Smit, Schaap en Den Boer, in tegenwoordigheid van Mr. Geel-Cieraad als griffier. De beslissing is op die datum in het openbaar uitgesproken.
        De griffier is verhinderd de uitspraak mede te ondertekenen.
      
      
      
      De voorzitter heeft geen bezwaar tegen afgifte door de griffier van een afschrift van de uitspraak in geanonimiseerde vorm.
      
      
      
	 
## Reference 	
We can extract references if we can look up HR numbers:

```
      [Zie ook arrest HR nummer 34000 (red.)]
```
([ECLI:NL:GHAMS:1997:AA4418](1997/AA4418.xml))    

```   
      [Zie ook arrest HR nummer 33393 (red.)]
```
([ECLI:NL:GHAMS:1997:AA4145](1997/AA4145.xml))
