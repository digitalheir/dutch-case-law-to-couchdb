# Gerechtshof te Amsterdam

## Header

Compare:

```xml  
      <para>Gerechtshof te Amsterdam</para>
      <para/>
      <para>kenmerk: P96/2906</para>
      <para/>
      <para>GERECHTSHOF TE AMSTERDAM</para>
      <para/>
      <para>Tweede Meervoudige Belastingkamer</para>
      <para/>
      <para>UITSPRAAK</para>
      <para/>
```
([ECLI:NL:GHAMS:1997:AA4418](/1997/AA4418.xml))
	  
with

```xml  
     <parablock>
        <para>Gerechtshof te Amsterdam</para>
        <para>Kenmerk: P95/5210	GERECHTSHOF TE AMSTERDAM</para>
        <para>	Derde Meervoudige Belastingkamer</para>
      </parablock>
      <para/>
      <para>	UITSPRAAK</para>
```
([ECLI:NL:GHAMS:1997:AA4145](/1997/AA4145.xml))
	  
We can't make assumptions about tags and whitespacing but GHAMS has very consistent prose for
- Court name
- local identifier 
- subsection of the court (belastingkamer). This information is not available as metadata!
- Where the verdict starts

# Case subject
Compare:

```xml  
      <para/>
      <para>op het beroep van de besloten vennootschap X B.V. te Z, belanghebbende,</para>
      <para/>
      <para>tegen</para>
      <para/>
      <para>een uitspraak van het Hoofd Douane P, de inspecteur.</para>
      <para/>
```
([ECLI:NL:GHAMS:1997:AA4418](/1997/AA4418.xml))
	  
With:

```xml
      </parablock>
      <para/>
      <para>	Uitspraak van het Gerechtshof te Leeuwarden,                        vierde enkelvoudige belastingkamer, op het	beroep van X te Z tegen de door de belastingdienst ondernemingen te P (:de inspecteur) opgelegde aanslag wegens navordering van inkomstenbelasting voor het jaar 1988.</para>
      <para/>
      <parablock>
```	
([ECLI:NL:GHAMS:1997:AA4145](/1997/AA4145.xml))  

The subject of the case is harder to extract. We know that:
- It is after the start of the verdict ('UITSPRAAK') and before the the first header ('1. Loop van het geding')

It may be possible to extract redacted names. They are single uppercase letters like X, Z, P, and sometimes a number of asterisks (*). Need to test precision.

Compare:	  

```xml
      <para>1. Loop van het geding</para>
      <para/>
```
([ECLI:NL:GHAMS:1997:AA4418](/1997/AA4418.xml))

With:	  
	
```xml
     <para>1. Loop van het geding</para>
      <para/>
```
([ECLI:NL:GHAMS:1997:AA4145](/1997/AA4145.xml))

Other headers:

```xml
      <para>2. Tussen partijen vaststaande feiten</para>
      <para>3. Geschil</para>
      <para>4. Standpunten van partijen</para>
      <para>5. Beoordeling van het geschil</para>
      <para>6. Proceskosten</para>
```
([ECLI:NL:GHAMS:1997:AA4418](/1997/AA4418.xml))    

Is similar to 

```xml
   <para>2. Tussen partijen vaststaande feiten</para>
      <para>3. Geschil</para>
      <para>4. Standpunten van partijen</para>
      <para>5. Beoordeling van het geschil</para>
      <para>6. Proceskosten</para>
```
([ECLI:NL:GHAMS:1997:AA4145](/1997/AA4145.xml))

Note that we can't just look for something that starts with a number and a period:

```xml
	    <para>"2.	Verliezen en vermissen. </para>
        <para>3.	Salderen van meer- en minderbevindingen</para>
```
([ECLI:NL:GHAMS:1997:AA4418](/1997/AA4418.xml))    

## Verdict
	  
	  <para>BESLISSING</para>
      <para>Het Hof bevestigt de uitspraak waarvan beroep.</para>
      <para/>
      <para>De uitspraak is vastgesteld op 11 december 1997 door mrs. Bijl, voorzitter, Boersma en Simons, leden van de belastingkamer, in tegenwoordigheid van mr. Visser als griffier. De beslissing is op die datum ter openbare zitting uitgesproken. </para>
      <para/>
      <para>De voorzitter van de belastingkamer heeft geen bezwaar tegen afgifte door de griffier van de uitspraak in geanonimiseerde vorm.</para>
      <para/>
     
    </uitspraak>
	
	   <para>7. Beslissing</para>
      <para/>
      <para>Het Hof bevestigt de bestreden uitspraak.</para>
      <para/>
      <para/>
      <parablock>
        <para>De uitspraak is vastgesteld op 7 mei 1997 door Mrs. Smit, Schaap en Den Boer, in tegenwoordigheid van Mr. Geel-Cieraad als griffier. De beslissing is op die datum in het openbaar uitgesproken.</para>
        <para>De griffier is verhinderd de uitspraak mede te ondertekenen.</para>
      </parablock>
      <para/>
      <para/>
      <para>De voorzitter heeft geen bezwaar tegen afgifte door de griffier van een afschrift van de uitspraak in geanonimiseerde vorm.</para>
      <para/>
      <para/>
      <para/>
	 
## Reference 	
We can extract references if we can look up HR numbers:

```xml
      <para>[Zie ook arrest HR nummer 34000 (red.)]</para>
```
([ECLI:NL:GHAMS:1997:AA4418](/1997/AA4418.xml))    

```   
      <para>[Zie ook arrest HR nummer 33393 (red.)]</para>
```
([ECLI:NL:GHAMS:1997:AA4145](/1997/AA4145.xml))