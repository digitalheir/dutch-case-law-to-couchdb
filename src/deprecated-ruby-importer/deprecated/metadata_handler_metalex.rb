# Enhances metadata when converting a Rechtspraak.nl XML document to Metalex XML

require 'cgi'

NS_RDF = 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
NS_RDFS = 'http://www.w3.org/2000/01/rdf-schema#'
NS_DCTERMS = 'http://purl.org/dc/terms/'
NS_PSI = 'http://psi.rechtspraak.nl/'
NS_BWB = 'bwb-dl'
NS_METALEX = 'http://www.metalex.eu/schema/1.0#'
NS_ECLI = 'https://e-justice.europa.eu/ecli'
NS_RECHTSPRAAK = 'http://doc.metalex.eu/rechtspraak/ontology/'
NS_RS = 'http://www.rechtspraak.nl/schema/rechtspraak-1.0'
NS_CVDR = 'http://decentrale.regelgeving.overheid.nl/cvdr/'
NS_EU = 'http://publications.europa.eu/celex/'
NS_TR = 'http://tuchtrecht.overheid.nl/'

RECHTSPRAAK_DEEPLINK_ROOT = "http://deeplink.rechtspraak.nl"


PREFIXES = {:rdf => NS_RDF, :rdfs => NS_RDFS, :dcterms => NS_DCTERMS, :psi => NS_PSI, :rs => NS_RS}

class MetadataStripper
  def initialize(xml, ecli)
    @xml = xml
    @ecli = ecli
    @work_uri = "#{RECHTSPRAAK_DEEPLINK_ROOT}/uitspraak?id=#{ecli}"

    @meta_counter = 0
    @id_meta = "#{ecli}:META"
    @mcontainer = Nokogiri::XML::Node.new "#{METALEX_PREFIX}:mcontainer", @xml

    @mcontainer['id'] = @id_meta
    @mcontainer['name'] = 'mcontainer'

    @mcontainer.add_namespace_definition 'rdf', NS_RDF
    @mcontainer.add_namespace_definition 'rdfs', NS_RDFS
    @mcontainer.add_namespace_definition 'dcterms', NS_DCTERMS
    @mcontainer.add_namespace_definition 'psi', NS_PSI
    @mcontainer.add_namespace_definition 'bwb', NS_BWB
    @mcontainer.add_namespace_definition 'ecli', NS_ECLI
    @mcontainer.add_namespace_definition 'cvdr', NS_CVDR
    @mcontainer.add_namespace_definition 'eu', NS_EU
    @mcontainer.add_namespace_definition 'tr', NS_TR
  end

  def strip_metadata
    # Find <rdf:RDF>
    rdf_tag = @xml.xpath('/open-rechtspraak/rdf:RDF', PREFIXES)
    rdf_tag.remove # remove from doc
    # Find all (two) <rdf:Description> tags
    metadata_tags = rdf_tag.xpath('./rdf:Description', PREFIXES)
    handle_register_metadata(metadata_tags.first)
    handle_doc_metadata(metadata_tags.last)

    # Just to be sure, remove all abstracts
    inhoudsindicaties = @xml.xpath('/open-rechtspraak/rs:inhoudsindicatie', PREFIXES)
    inhoudsindicaties.each do |inhoudsindicatie|
      inhoudsindicatie.remove
    end

    @mcontainer
  end

  def handle_register_metadata(register_metadata)
    ###
    # Register metadata
    ###

    # ECLI id. We already have the id; irrelevant
    # handle_metadata(about, register_metadata, 'dcterms:identifier')

    # Doctype: text/xml; irrelevant
    # handle_metadata(about, register_metadata, 'dcterms:format')

    # Same as document accessRights: fixed value of 'public'
    # handle_metadata(about, register_metadata, 'dcterms:accessRights')

    # metadata modified
    handle_metadata(register_metadata, @id_meta, 'dcterms:modified') # About the metadata

    # We only use issued from document metadata
    # handle_metadata(register_metadata, 'dcterms:issued')

    # We only use publisher from document metadata
    # handle_metadata(register_metadata, 'dcterms:publisher')

    # We only use language from document metadata
    # handle_metadata(register_metadata, 'dcterms:language')

    # LJN number
    handle_metadata(register_metadata, @work_uri, 'dcterms:replaces')
    # If the current ECLI is not valid, this points to a replacement ECLI. Note it's only about the identifier.
    handle_metadata(register_metadata, @work_uri, 'dcterms:isReplacedBy')
    # URI for the court
    handle_creator(register_metadata, @work_uri)
    # Judge
    handle_metadata(register_metadata, @work_uri, 'dcterms:contributor')
    # date of judgment
    handle_metadata(register_metadata, @work_uri, 'dcterms:date')

    # Add aliases
    # NOTE: @rdf:language fixed to NL is ignored
    handle_metadata(register_metadata, @work_uri, 'dcterms:alternative')

    # 'Uitspraak' or 'Conclusie'
    handle_case_type(register_metadata, @work_uri)
    # Ex: <psi:procedure rdf:language="nl"
    #      rdfs:label="Procedure"
    #      resourceIdentifier="http://psi.rechtspraak.nl/procedure#eersteAanlegMeervoudig">
    #       Eerste aanleg - meervoudig
    #     </psi:procedure>
    handle_metadata(register_metadata, @work_uri, 'psi:procedure')

    #"Indien sprake is van een afhankelijkheid van een specifieke periode waarbinnen de
    # betreffende zaak moet worden beoordeeld. Bijvoorbeeld in het geval van belasting
    # gerelateerde onderwerpen."
    #
    #handle_temporal(register_metadata, @about)  # TODO 'dcterms:temporal'

    handle_references(register_metadata, @work_uri)
    handle_coverage(register_metadata, @work_uri) # Jurisdiction
    # Where versions of this judgment can be found. Might be different expressions (e.g., edited and annotated)
    handle_has_version(register_metadata, @work_uri)
    # Relations to other cases
    handle_relations(register_metadata, @work_uri)
    # Existing case numbers
    handle_case_numbers(register_metadata, @work_uri)
    # What kind of law this case is about (e.g., 'staatsrecht)
    handle_subject(register_metadata, @work_uri)
  end

  def handle_doc_metadata(text_document_metadata)
    ###
    # Document metadata
    ###

    # ECLI id suffixed with :DOC; irrelevant
    # handle_metadata(text_document_metadata, 'dcterms:identifier')

    # handle_metadata(text_document_metadata, 'dcterms:format')  # 'text/html', irrelevant

    # Hardcoded 'public', some manifestations may be non-public. Like ones with their names unredacted.
    handle_metadata(text_document_metadata, @work_uri, 'dcterms:accessRights')
    # Document modified
    handle_metadata(text_document_metadata, @work_uri, 'dcterms:modified')
    # Document publication date in YYYY-MM-DD
    handle_metadata(text_document_metadata, @work_uri, 'dcterms:issued')
    handle_metadata(text_document_metadata, @work_uri, 'dcterms:publisher') # Publisher
    handle_metadata(text_document_metadata, @work_uri, 'dcterms:title') # Document title

    # Document language; already handled
    # handle_metadata(ml_converter, expression_uri, text_document_metadata, 'dcterms:language')

    # Short summary
    handle_abstract(text_document_metadata, @work_uri) # TODO add lang
  end

  # Returns a <meta> tag with given triple
  def create_meta(subject, predicate, object)
    element = Nokogiri::XML::Node.new 'meta', @xml
    element['name'] = 'meta'
    element['about'] = subject
    element['property'] = predicate
    element['content'] = object
    @meta_counter += 1
    element['id'] = "#{@id_meta}:#{@meta_counter}" # '<ECLI>:META:<meta_counter>'

    element
  end

  def handle_metadata(tree, subject, verb)
    if verb == 'contributor'
      puts tree
    end

    elements = tree.xpath("./#{verb}", PREFIXES)
    if !elements or elements.length <= 0
      # could_not_find = "Could not find #{verb} in #{tree.name}"
      # puts could_not_find
    else
      # if elements.length > 1
        # found_more_msg = "Found #{elements.length} elements for #{verb} in #{@ecli}"
        # puts found_more_msg
      # end
      elements.each do |element|
        # Get text content
        if element and element.element_children.length > 0
          puts "Found #{element.element_children.length} child nodes in tag for #{verb} in #{subject}"
        end

        predicate_label = element['rdfs:label'] # human-readable label for the predicate
        href = element['resourceIdentifier'] # reference to uri
        content_text = element.text

        # Decide how the triples work
        if href # Use resource id as object and inner text as object label
          @mcontainer << create_meta(subject, verb, href)
          if content_text
            @mcontainer << create_meta(href, "rdfs:label", content_text)
          end
        else # Use inner text as the object
          if content_text
            @mcontainer << create_meta(subject, verb, content_text)
          else
            puts "WARNING: No value found for #{verb}"
          end

          if predicate_label != nil # Add label for predicate
            @mcontainer << create_meta(verb, "rdfs:label", predicate_label)
          end
        end
      end
    end
  end

# Extract abstract. If the abstract has less than 2 characters, it's ignored
# Example:
#
# <dcterms:abstract>Bla Bla</dcterms:abstract>
#
# Becomes
#
# <uri> dcterms:abstract "Bla bla"^string
  def handle_abstract(tree, uri)
    predicate ='dcterms:abstract'
    elements = tree.xpath("./#{predicate}", PREFIXES)
    if elements.length > 0
      if elements.length > 1
        puts "Found #{elements.length} elements for #{predicate} in #{uri}"
      end

      elements.each do |element|
        abstract = element.text.strip # fallback if there's no resourceIdentifier
        if element['resourceIdentifier']
          inhoudsindicaties = @xml.xpath('/open-rechtspraak/rs:inhoudsindicatie', PREFIXES)
          inhoudsindicaties.each do |inhoudsindicatie|
            abstract = inhoudsindicatie.text.strip
            inhoudsindicatie.remove
          end
        end
        if abstract and abstract.length > 1 # Don't add abstract if it's just a single character (most likely a dash), or nothing at all
          @mcontainer << create_meta(uri, predicate, abstract) # NOTE: currently, abstract is just a string, but this may change to be a more intricate structure (with xml tags)
        end
      end
    end
  end

# Example:
#
# <psi:zaaknummer rdfs:label="Zaaknr">AWB 98/539</psi:zaaknummer>
#
# Becomes:
#
# <uri> <http://psi.rechtspraak.nl/zaaknummer> "AWB 98/539"^string
  def handle_case_numbers(tree, uri)
    predicate = 'psi:zaaknummer'
    elements = tree.xpath("./#{predicate}", PREFIXES)
    # if elements.length > 1
    #   puts "Found #{elements.length} elements for #{predicate} in #{uri}"
    # end
    elements.each do |element|
      # A string like '97/8236 TW, 97/8241 TW' is probably two case numbers
      case_numbers = element.text.split(",")

      case_numbers.each do |case_number|
        trimmed = case_number.strip
        if trimmed.length > 0
          @mcontainer << create_meta(uri, predicate, trimmed)
        end
      end
    end
  end

# Example:
#
# <dcterms:subject rdfs:label="Rechtsgebied"
#   resourceIdentifier="http://psi.rechtspraak.nl/rechtsgebied#bestuursrecht_socialezekerheidsrecht">
#     Bestuursrecht; Socialezekerheidsrecht
# </dcterms:subject>
#
# Becomes
#
# <uri> dcterms:subject <http://psi.rechtspraak.nl/rechtsgebied#bestuursrecht>
# <uri> dcterms:subject <http://psi.rechtspraak.nl/rechtsgebied#socialezekerheidsrecht>
# <http://psi.rechtspraak.nl/rechtsgebied#bestuursrecht> rdfs:label "Bestuursrecht"
# <http://psi.rechtspraak.nl/rechtsgebied#socialezekerheidsrecht> rdfs:label "Socialezekerheidsrecht"
  def handle_subject(tree, uri)
    predicate = 'dcterms:subject'
    elements = tree.xpath("./#{predicate}", PREFIXES)
    elements.each do |element|
      subjects = element.text.split(/;|,/)

      subjects.each do |subject|
        trimmed = subject.strip
        if trimmed.length > 0
          uri_obj = trimmed.downcase.gsub(' ', '_')
        end
        object_uri = 'http://psi.rechtspraak.nl/rechtsgebied#' + CGI.escape(uri_obj)
        @mcontainer << create_meta(uri, predicate, object_uri)
        @mcontainer << create_meta(object_uri, 'rdfs:label', trimmed)
      end
    end
  end

# Handle relation between ECLIs, for example:
#
#   <dcterms:relation
#     rdfs:label="Formele relatie"
#     ecli:resourceIdentifier="ECLI:NL:PHR:2013:860"
#     psi:type="http://psi.rechtspraak.nl/conclusie"
#     psi:aanleg="http://psi.rechtspraak.nl/eerdereAanleg"
#     psi:gevolg="http://psi.rechtspraak.nl/gevolg#contrair">
#       Conclusie: ECLI:NL:PHR:2013:860, Contrair
#   </dcterms:relation>
#
#   <dcterms:relation
#     rdfs:label="Formele relatie"
#     ecli:resourceIdentifier="ECLI:NL:RBONE:2013:BZ5236"
#     psi:type="http://psi.rechtspraak.nl/sprongcassatie"
#     psi:aanleg="http://psi.rechtspraak.nl/eerdereAanleg"
#     psi:gevolg="http://psi.rechtspraak.nl/gevolg#bekrachtiging/bevestiging">
#       In sprongcassatie op: ECLI:NL:RBONE:2013:BZ5236, Bekrachtiging/bevestiging
#   </dcterms:relation>
#
# http://dublincore.org/documents/dcmi-terms/#terms-relation says:
#  "Recommended best practice is to identify the related resource by means of a string
#   conforming to a formal identification system"
#
# NOTE: this relation is reified so that we can make meta-statements about it.
#       See stackoverflow.com/questions/5671227/ddg#5671407
  def handle_relations(tree, subject_uri)
    predicate = 'dcterms:relation'

    elements = tree.xpath('./dcterms:relation', PREFIXES)
    for element in elements
      # Parse reference to ECLI
      referent_ecli = element['ecli:resourceIdentifier']
      # NOTE: documentation says 'typeRelatie'. But the data says 'type'
      relation_type = element['psi:type']
      unless relation_type
        relation_type = element['psi:typeRelatie']
      end
      relation_aanleg = element['psi:aanleg']

      # Create uri for this relation, in order to reify the statement
      relation_uri = "#{RECHTSPRAAK_DEEPLINK_ROOT}/relation?subject=#{@ecli}&object=#{referent_ecli}"

      # Build triple
      @mcontainer << create_meta(relation_uri, "rdf:subject", subject_uri)
      @mcontainer << create_meta(relation_uri, "rdf:predicate", predicate)
      @mcontainer << create_meta(relation_uri, "rdf:object", "#{RECHTSPRAAK_DEEPLINK_ROOT}/uitspraak?id=#{referent_ecli}")

      # Add additional information about this triple
      relation_gevolg = element['psi:gevolg'] # "Het gevolg van de behandeling in latere aanleg."
      if relation_gevolg and relation_gevolg.strip.length > 0
        @mcontainer << create_meta(relation_uri, 'psi:gevolg', relation_gevolg.strip) # http://psi.rechtspraak.nl/gevolg#(Gedeeltelijke) vernietiging en zelf afgedaan
      end
      @mcontainer << create_meta(relation_uri, "psi:typeRelatie", relation_type)
      @mcontainer << create_meta(relation_uri, "psi:aanleg", relation_aanleg)
      @mcontainer << create_meta(relation_uri, "rdf:type", "rdf:statement")

      # Human readable label for dc:relation
      predicate_label = element['rdfs:label']
      @mcontainer << create_meta(predicate, "rdfs:label", predicate_label)
    end
  end

# Example (list is always assumed to be present):
#
# <dcterms:hasVersion rdfs:label="Vindplaatsen" resourceIdentifier="http://psi.rechtspraak.nl/vindplaats">
#   <rdf:list>
#     <rdf:li>Rechtspraak.nl</rdf:li>
#     <rdf:li>V-N 2013/59.23.30</rdf:li>
#     <rdf:li>NJB 2013/2526</rdf:li>
#   </rdf:list>
# </dcterms:hasVersion>
#
# Will be converted to:
#
# <sub_uri> dcterms:hasVersion "Rechtspraak.nl"^string
# <sub_uri> dcterms:hasVersion "V-N 2013/59.23.30"^string
# <sub_uri> dcterms:hasVersion "NJB 2013/2526"^string
#
  def handle_has_version(tree, subject_uri)
    predicate = 'dcterms:hasVersion'
    elements = tree.xpath("./#{predicate}", PREFIXES)
    predicate = NS_DCTERMS + 'hasVersion'
    if elements.length > 1
      puts "Found #{elements.length} elements for #{predicate} in #{subject_uri}"
    end
    elements.each do |has_version_element|
      item_lists = has_version_element.xpath('./rdf:list', PREFIXES)
      item_lists.each do |item_list|
        list_items = item_list.xpath('./rdf:li', PREFIXES)
        list_items.each do |item|
          @mcontainer << create_meta(subject_uri, predicate, item.text)
        end
      end
    end
  end

# Example:
#
# <dcterms:coverage>NL</dcterms:coverage>
#
# Becomes:
#
# <subj_uri> dcterms:coverage <http://deeplink.rechtspraak.nl/jurisdication?id=NL>
# Part of the hierarchy in the document work id: /country code/name of court/date or year/issue number/
  def handle_coverage(tree, subject_uri)
    predicate = 'dcterms:coverage'
    elements = tree.xpath("./#{predicate}", PREFIXES)
    if elements.length > 1
      puts "Found #{elements.length} elements for #{predicate} in #{subject_uri}"
    end
    elements.each do |element|
      jurisdiction_uri = element.text
      unless jurisdiction_uri.start_with? 'http://'
        jurisdiction_uri = "#{RECHTSPRAAK_DEEPLINK_ROOT}/jurisdiction?id=#{element.text}"
      end
      @mcontainer << create_meta(subject_uri, predicate, jurisdiction_uri)
    end
  end

# Example:
#
# <dcterms:references
#   rdfs:label="Wetsverwijzing"
#   bwb:resourceIdentifier="1.0:v:BWB:BWBR0011823&artikel=59">
#     Vreemdelingenwet 2000 59
# </dcterms:references>
#
# Becomes
#
# <uri> dcterms:references "1.0:v:BWB:BWBR0011823&artikel=59"
#TODO <uri> metalex:cites <http://doc.metalex.eu/id/BWBR0011823/artikel/59>
#
# NOTE: Discussed whether this should this references an *expression* of a law,
# because it refers to the law at a particular time (usually the time of the court case).
# I don't resolve the expression because we can't know with full certainty to what time it refers.
# It's rechtspraak.nl's responsibility to get the reference right anyway.
  def handle_references(tree, subject)
    predicate = 'dcterms:references'
    elements = tree.xpath("./#{predicate}", PREFIXES)
    elements.each do |element|
      resource = nil
      ref_source = nil
      element.attributes.each do |name, attr|
        if name == 'resourceIdentifier' # Can be bwb:resourceIdentifier or cvdr:resourceIdentifier (for example in ECLI:NL:GHAMS:2014:1)
          case attr.namespace.prefix
            when 'bwb', 'cvdr'
            else
              puts "Found ref with prefix #{attr.namespace.prefix}"
          end
          ref_source = attr.namespace.prefix
          resource = attr.value
        end
      end
      unless resource
        puts "could not find resource_id of this element:"
        puts element.to_s
        return
      end

      # NOTE: I feel like both metalex:cites and dcterms:references are appropriate predicates, so I'll use dcterms:references for the juriconnect reference, and metalex:cites for the metalex document reference
      @mcontainer << create_meta(subject, predicate, resource)
      @mcontainer << create_meta(resource, 'dcterms:hasFormat', ref_source)

      # TODO use script of Radboud's students to resolve uri
      # metalex_uri = get_target(resource_id)
      # if !target
      #   logging.warning("Did not find a resource identifier with '" + element.text + "'. Ignoring reference.")
      #   return
      # end
      # Go on if there's a resource id

      # TODO
      # @mcontainer << create_meta(ml_converter, subject_uri, "metalex:cites", metalex_uri)
      # @mcontainer << create_meta(resource, 'dcterms:hasFormat', ref_source)
    end
  end

# Example:
#
# <dcterms:creator
#  rdfs:label="Instantie"
#  resourceIdentifier="http://standaarden.overheid.nl/owms/terms/Centrale_Raad_van_Beroep"
#  scheme="overheid.RechterlijkeMacht">
#    Centrale Raad van Beroep
# </dcterms:creator>
#
# NOTE: psi:afdeling is deprecated, so we won't parse it
  def handle_creator(tree, subject)
    predicate = "dcterms:creator"
    creators = tree.xpath("./#{predicate}", PREFIXES)
    creators.each do |creator|
      # A reference an OWMS uri (http://standaarden.overheid.nl/owms)
      court_uri = creator['resourceIdentifier']
      unless court_uri
        # If there's no OWMS uri, the site falls back to a psi.rechtspraak-prefixed uri
        court_uri = creator['psi:resourceIdentifier']
      end
      tag_content = creator.text.strip

      if court_uri
        @mcontainer << create_meta(subject, predicate, court_uri)

        # Give the court a human-readable name
        if tag_content.length > 0
          @mcontainer << create_meta(court_uri, 'rdfs:label', tag_content)
        end
      else
        if tag_content.length > 0
          # Court only has a string name, no http uri
          @mcontainer << create_meta(subject, predicate, court_uri)
          puts "WARNING: Court #{tag_content} only has a string name, no http uri"
        else
          puts "WARNING: Court has no name, and no http uri"
        end
      end

      # The relation has a human-readable label
      predicate_label = creator['rdfs:label'].strip
      if predicate_label.length > 0
        @mcontainer << create_meta(predicate, "rdfs:label", predicate_label)
      end
    end
  end

# Example:
#
# <dcterms:type rdf:language="nl" resourceIdentifier="http://psi.rechtspraak.nl/uitspraak">Uitspraak</dcterms:type>
#
# Becomes:
#
# <subject> dcterms:type <http://psi.rechtspraak.nl/uitspraak>
# <http://psi.rechtspraak.nl/uitspraak> rdfs:label "Uitspraak"
#
# rdf:language is fixed to nl, so we'll ignore
  def handle_case_type(tree, subject)
    predicate = 'dcterms:type'
    types = tree.xpath("./#{predicate}", PREFIXES)
    types.each do |type| # Should be just 1
      type_uri = type['resourceIdentifier']
      @mcontainer << create_meta(subject, predicate, type_uri)

      label = type.text.strip
      if label.length > 0
        @mcontainer << create_meta(type_uri, "rdfs:label", label)
      end
    end
  end
end