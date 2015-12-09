var assert = require('assert');
var xml = require('../xml_util');
var stats_views = require('../ddocs/stats/views');
var doc = require('./doc/doc');
var doc_rich = require('./doc/doc_rich');
var doc_hoge_raad = require('./doc/doc_hoge_raad');
var doc_with_image = require('./doc/doc_with_image');

describe('xml_utils', function () {
    it('should loop over children', function () {
        var i = 0;
        var name = "name";
        var child = [1, name, []];
        xml.forAllChildren([1, name, [child]], function (n) {
            i++;
            assert.equal(n, child);
            assert.equal(xml.getTagName(n), name);
            assert.equal(xml.getChildren(n).length, 0);

        });
        assert.equal(i, 1);
    });
});

describe('crf_tokenize', function () {
    var crftt = require('../crf_tokenizer');
    it('should tokenize correctly', function () {

    });
});

///////////////////


function testSecondaryView(f, doc) {
    var emitted = [];
    //noinspection JSUnusedLocalSymbols
    var emit = function (a, b) {
        emitted.push([a, b]);
    };
    f = eval("(" + f.map.toString() + ")");
    f(doc);
    //console.log(emitted);
    return emitted;
}

function testSecondaryViewOnDocs(f, docs) {
    var emitted = [];
    //noinspection JSUnusedLocalSymbols
    var emit = function (a, b) {
        emitted.push([a, b]);
    };
    f = eval("(" + f.map.toString() + ")");
    //console.log(docs.length)
    for (var i = 0; i < docs.length; i++) {
        f(docs[i]);
    }
    //console.log(emitted);
    return emitted;
}

describe('stats', function () {
    it('should emit doc that has section tag', function () {
        var emitted = testSecondaryViewOnDocs(stats_views.docs_with_section_tag, [doc, doc_rich]);

        assert.equal(emitted.length, 2);
        assert.equal(emitted[0][0][0], false);
        assert.equal(emitted[1][0][0], true);
        assert.equal(emitted[0][1], 1);
        assert.equal(emitted[1][1], 1);
        //assert.equal(emitted[1][0][0], true);
        //assert.equal(emitted[1][1], 0);
    });
    it('should emit numbers', function () {
        //var emitted = testSecondaryViewOnDocs(stats_views.section_nrs, [doc, doc_rich]);
        //
        //assert.equal(emitted.length, 36);
        //assert.equal(emitted[0][0][0], "1");
        //assert.equal(emitted[1][0][0], ".");
        //assert.equal(emitted[2][0][0], "2");
        //require('fs').writeFileSync('./uhh.json', JSON.stringify(emitted))
    });
    //it('should emit titles', function () {
    //    var emitted = testSecondaryViewOnDocs(views.section_titles, [doc, doc_rich]);
    //
    //    assert.equal(emitted.length, 3);
    //    assert.equal(emitted[0][0][0], 'i. ontstaan en loop van het geding');
    //});
    it('should emit title tokens', function () {
        var emitted = testSecondaryViewOnDocs(stats_views.words_in_title, [doc, doc_rich]);

        assert.equal(emitted.length, 14);
        assert.equal(emitted[0][0], 'i');
        assert.equal(emitted[2][0], 'ontstaan');
    });
    it('should emit doc with image', function () {
        var emitted = testSecondaryViewOnDocs(stats_views.docs_with_image, [doc_with_image, doc_rich]);
        assert.equal(emitted.length, 1);
        //assert.equal(emitted[0][0][0], true);
        //assert.equal(emitted[0][1], 1);
    });

    it('should correctly emit parents of <nr> tags', function () {
        var emitted = testSecondaryViewOnDocs(stats_views.parents_of_nr, [doc, doc_rich]);
        assert.equal(emitted.length, 11);
        assert.equal(emitted[0][0][0], 'paragroup');
    });
});

/////////////////////////////////////////

var dev_views = require('../ddocs/query_dev/views');

describe('query_dev', function () {
    it('should index hoge raad', function () {
        var emitted = testSecondaryView(dev_views.hoge_raad_by_date, doc_hoge_raad);
        assert.equal(emitted.length, 1);
        assert.equal(emitted[0][0][0], 1984);
        assert.equal(emitted[0][0][1], 1);
        assert.equal(emitted[0][0][2], 17);
    });
    it('should index ecli_last_modified', function () {
        //assert.equal(true, true);
    });

});


/////////////////////////////////////////////////////


describe('crf', function () {
    var crfViews = require('../ddocs/crf/views');
    describe('views', function () {
        it('should tokenize', function () {
            var t = require('../crf_tokenizer');
            var nat = require('../natural');
            var tokens = t.tokenize(new nat.WordPunctTokenizer(), doc_rich.xml);
            assert.equal(tokens.length, 1596);
        });

        it('should emit tokens', function () {
            function testCorrectTokenization(emitted) {
                assert.equal(emitted.length, 1380);
                assert.equal(emitted[2][0][0], 'ECLI:NL:CRVB:2002:2');
                assert(emitted[2][0][1] === 2);
                assert.equal(emitted[2][1].string, "99");
                assert.equal(emitted[2][1].isNumber, true);
                assert.equal(emitted[2][1].isPeriod, false);
                assert.equal(emitted[2][1].isCapitalized, false);

                assert.equal(emitted[66][1].string, ",");
                assert.equal(emitted[6][1].string, "_CARRIAGE_RETURN");

                for (var i = 0; i < emitted.length; i++) {
                    assert(!emitted[i][1].string.match(/\s/)); //No whitespace should be kept
                    //console.log(i+": "+emitted[i][1].string);
                }
            }

            doc_rich.useForCrf = 1;
            testCorrectTokenization(testSecondaryView(crfViews.crfTestTokens, doc_rich));
            doc_rich.useForCrf = 0;
            testCorrectTokenization(testSecondaryView(crfViews.crfTrainTokens, doc_rich));
        });
    });

});

//////////////////////////////////////////////////////

var query_views = require('../ddocs/query/views');
var indexes = require('../ddocs/query/indexes');
var example_index =
{
    "subject": ["Strafrecht", {"store": "yes", "facet": true}],
    "abstract": ["Verdachte heeft samen met zijn mededader een juwelierszaak op brutale wijze overvallen en de in de zaak aanwezige eigenaar en een personeelslid met een (op een) vuurwapen (gelijkend voorwerp) bedreigd. Zij hebben daarbij voor ruim € 117.000,- aan sieraden buit gemaakt.\n        Nadere bewijsoverweging m.b.t herkenning verdachte door verbalisant aan de hand van foto's in korpsbericht.\n        5 jaar gevangenisstraf.", {
        "store": "yes",
        "facet": false
    }],
    "title": ["ECLI:NL:GHAMS:2002:AF3970 Gerechtshof Amsterdam , 21-11-2002 / 23-001647-02", {
        "store": "yes",
        "facet": false
    }],
    "ecli": ["ECLI:NL:GHAMS:2002:AF3970", {"store": "yes", "facet": false}],
    "default": ["ECLI:NL:GHAMS:2002:AF3970 Strafrecht Verdachte heeft samen met zijn mededader een juwelierszaak op brutale wijze overvallen en de in de zaak aanwezige eigenaar en een personeelslid met een (op een) vuurwapen (gelijkend voorwerp) bedreigd. Zij hebben daarbij voor ruim € 117.000,- aan sieraden buit gemaakt.\n        Nadere bewijsoverweging m.b.t herkenning verdachte door verbalisant aan de hand van foto's in korpsbericht.\n        5 jaar gevangenisstraf. ECLI:NL:GHAMS:2002:AF3970 Gerechtshof Amsterdam , 21-11-2002 / 23-001647-02 ECLI:NL:GHAMS:2002:AF3970", {"store": "no"}],
    "innerText": ["arrestnummer rolnummer 23-001647-02 datum uitspraak 21 november 2002 tegenspraak Verkort arrest van het Gerechtshof te Amsterdam gewezen op het hoger beroep ingesteld tegen het vonnis van de rechtbank te Amsterdam van 13 mei 2002 in de strafzaak onder parketnummer 13/021329-01 tegen [verdachte], geboren te [plaats] (Marokko) op [...] 1977, wonende te [adres], thans verblijvende in P.I. Midden Holland te Haarlem. Beperkt appel Het hoger beroep van de verdachte is kennelijk niet gericht tegen de in het vonnis waarvan beroep genomen beslissing ten aanzien van het onder 2 tenlastegelegde. Het onderzoek van de zaak Dit arrest is gewezen naar aanleiding van het onderzoek op de terechtzitting in eerste aanleg van 18 december 2001 en 29 april 2002 en in hoger beroep van 7 november 2002. Het hof heeft kennis genomen van de vordering van de advocaat-generaal en van hetgeen door de verdachte en de raadsman naar voren is gebracht. De tenlastelegging Aan de verdachte is - voorzover in hoger beroep aan de orde - tenlastegelegd hetgeen vermeld staat in de inleidende dagvaarding. Van de dagvaarding is een kopie in dit arrest gevoegd. De inhoud daarvan wordt hier overgenomen. Het vonnis waarvan beroep Het hof zal het vonnis waarvan beroep - voorzover aan zijn oordeel onderworpen - vernietigen omdat het zich daarmee niet geheel verenigt. De bewezenverklaring Naar het oordeel van het hof is wettig en overtuigend bewezen hetgeen aan de verdachte onder 1 is tenlastegelegd, met dien verstande dat: hij op 31 juli 2001 te Amsterdam tezamen en in vereniging met een ander, met het oogmerk van wederrechtelijke toeëigening in een juwelierswinkel genaamd juwelier [naam], gevestigd [adres] heeft weggenomen ringen en horloges en sieraden met een totale verkoopwaarde van ongeveer fl. 260.000,-, toebehorende aan juwelier [naam], welke diefstal werd voorafgegaan en vergezeld en gevolgd van bedreiging met geweld tegen [slachtoffer 1] en [slachtoffer 2], beiden werkzaam in en aanwezig in voornoemde winkel, gepleegd met het oogmerk om die diefstal voor te bereiden en gemakkelijk te maken en om bij betrapping op heterdaad aan zichzelf en aan een andere deelnemer de vlucht mogelijk te maken, welke bedreiging met geweld hierin bestond dat hij, verdachte en/of zijn mededader opzettelijk gewelddadig en dreigend een pistool, in elk geval een op een vuurwapen gelijkend voorwerp, aan die [slachtoffer 1] en die [slachtoffer 2] heeft/hebben getoond en tegen die [slachtoffer 1] en die [slachtoffer 2] heeft/hebben gezegd: \"Overval, geen geintjes\" en \"Doe die deur open; open de deur\" althans woorden van gelijke aard en strekking en met een hamer ruiten van een vitrine heeft/hebben ingeslagen. Voor zover in de tenlastelegging taal- en/of schrijffouten voorkomen, zijn deze in de bewezenverklaring verbeterd. Blijkens het verhandelde ter terechtzitting is de verdachte daardoor niet geschaad in de verdediging. Hetgeen onder 1 meer of anders is tenlastegelegd, is niet bewezen. De verdachte moet hiervan worden vrijgesproken. Het hof grondt zijn overtuiging dat de verdachte het bewezenverklaarde heeft begaan, op de feiten en omstandigheden die in de bewijsmiddelen zijn vervat. Nadere bewijsoverweging De raadsman heeft ter terechtzitting in hoger beroep onder meer aangevoerd - zakelijk weergegeven conform de inhoud van zijn pleitnota - dat de foto's uit het korpsbericht, aan de hand waarvan de verbalisant [verbalisant] de verdachte als één van de plegers van de overval heeft herkend, objectief gezien niet duidelijk genoeg zijn om een betrouwbare herkenning op te kunnen leveren. Het proces-verbaal waarin de aan de hand van die foto gerelateerde herkenning van verdachte door [verbalisant] is opgenomen, mag dan ook niet als bewijsmiddel worden gebruikt, aldus de raadsman. In het dossier (doorgenummerde bladzijde 51) bevinden zich fotokopieën van de door de raadsman bedoelde foto's. Het hof is van oordeel dat deze foto's afbeeldingen weergeven die in kwalitatieve zin toereikend kunnen zijn voor herkenning zoals door [verbalisant] gedaan en gerelateerd in een door hem opgesteld proces-verbaal. Voor bewijsuitsluiting op de door de raadsman aangevoerde grond bestaat dan ook geen grond, terwijl evenmin is gebleken van feiten of omstandigheden die tot een ander oordeel dienen te leiden. Het verweer van de raadsman wordt derhalve verworpen. De strafbaarheid van het feit Er is geen omstandigheid aannemelijk geworden die de strafbaarheid van het bewezenverklaarde uitsluit, zodat dit strafbaar is. Het onder 1 bewezenverklaarde levert op: diefstal, voorafgegaan, vergezeld en gevolgd van bedreiging met geweld tegen personen, gepleegd met het oogmerk om die diefstal voor te bereiden of gemakkelijk te maken, of om, bij betrapping op heterdaad, aan zichzelf of andere deelnemers de vlucht mogelijk te maken, terwijl het feit wordt gepleegd door twee of meer verenigde personen. De strafbaarheid van de verdachte Er is geen omstandigheid aannemelijk geworden die de strafbaarheid van de verdachte uitsluit, zodat de verdachte strafbaar is. De op te leggen straf De rechtbank heeft de verdachte veroordeeld tot gevangenisstraf voor de duur van vijf jaren. Namens verdachte is hoger beroep ingesteld tegen voormeld vonnis. De advocaat-generaal heeft gevorderd dat het hof het vonnis waarvan beroep zal bevestigen. Het hof heeft in hoger beroep de op te leggen straf bepaald op grond van de ernst van het feit en de omstandigheden waaronder dit is begaan en gelet op de persoon van de verdachte. Het hof heeft daarbij in het bijzonder het volgende in beschouwing genomen. Verdachte heeft samen met zijn mededader een juwelierszaak op brutale wijze overvallen en de in de zaak aanwezige eigenaar en een personeelslid met een (op een) vuurwapen (gelijkend voorwerp) bedreigd. Zij hebben daarbij voor ruim € 117.000,- aan sieraden buit gemaakt. De slachtoffers hebben hevige angsten moeten doorstaan. De ervaring leert, dat slachtoffers van een gewapende overval, daarvan in het algemeen een langdurige en ernstige psychische nasleep ondervinden. Daarnaast heeft verdachte er aan bijgedragen dat in de samenleving bestaande gevoelens van onveiligheid en onrust, in het bijzonder in de juweliersbranche, blijven bestaan en worden versterkt. De verdachte is blijkens een hem betreffend uittreksel uit het Justitieel Documentatieregister van 18 juli 2002 al verschillende malen eerder veroordeeld voor het plegen van misdrijven, ook voor misdrijven soortgelijk aan het onderhavige. Deze veroordelingen hebben verdachte er niet van weerhouden zich weer schuldig te maken aan een ernstig misdrijf, zoals hiervoor is bewezenverklaard. Gelet op het voorgaande acht het hof oplegging van gevangenisstraf voor de duur van vijf jaren, passend en geboden. De toepasselijke wettelijke voorschriften De opgelegde straf is gegrond op de artikelen 310 en 312 van het Wetboek van Strafrecht. De beslissing Het hof: vernietigt het vonnis waarvan beroep - voorzover aan zijn oordeel onderworpen - en doet opnieuw recht; verklaart wettig en overtuigend bewezen dat de verdachte het onder 1 tenlastegelegde feit, zoals hierboven omschreven, heeft begaan; verklaart niet wettig en overtuigend bewezen hetgeen aan de verdachte onder 1 meer of anders is tenlastegelegd en spreekt hem daarvan vrij; verklaart dat het bewezenverklaarde het hierboven vermelde strafbare feit oplevert; verklaart het bewezenverklaarde strafbaar en ook de verdachte daarvoor strafbaar; veroordeelt de verdachte tot een gevangenisstraf voor de tijd van 5 (VIJF) JAREN; bepaalt dat de tijd die door de veroordeelde vóór de tenuitvoerlegging van deze uitspraak in verzekering en in voorlopige hechtenis is doorgebracht, bij de uitvoering van de opgelegde gevangenisstraf in mindering wordt gebracht. Dit arrest is gewezen door de vijfde meervoudige strafkamer van het gerechtshof te Amsterdam, waarin zitting hadden mrs. Voncken, Veldhuisen en Schalken, in tegenwoordigheid van mr. Van Iperen als griffier, en is uitgesproken op de openbare terechtzitting van dit gerechtshof van 21 november 2002. Mr. Schalken is buiten staat dit arrest mede te ondertekenen.", {"store": "no"}]
};

describe('query', function () {
    describe('indexes', function () {
        var indexesMap = {};
        var index = function (fieldName, strValue, options) {
            indexesMap[fieldName] = [strValue, options];
        };
        var f = eval("(" + indexes.search.index.toString() + ")");
        f(doc);

        it('should index like we expect', function () {
            //console.log(typeof  indexesMap.innerText[0].startsWith);
            //console.log(indexesMap.innerText)
            assert.equal(indexesMap.innerText[0].substring(0, 'arrestnummer'.length), 'arrestnummer');
            //console.log(JSON.stringify(indexesMap));
            assert.equal(example_index.subject[0], indexesMap.subject[0]);
            assert.equal(example_index.abstract[0], indexesMap.abstract[0]);
            assert.equal(example_index.title[0], indexesMap.title[0]);
            assert.equal(example_index.ecli[0], indexesMap.ecli[0]);
        });
    });


    //describe('views', function () {
    //    describe('ecli_last_modified', function () {
    //        it('should show correctly', function () {
    //            //assert.equal(true, true);
    //        });
    //    });
    //});
});