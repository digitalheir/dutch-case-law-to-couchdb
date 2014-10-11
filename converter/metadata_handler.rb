# Enhances metadata when converting a Rechtspraak.nl XML document to Metalex XML

require 'cgi'
require 'rdf'
require 'json/ld'

# noinspection RubyStringKeysInHashInspection
# context = [
#     'http://assets.lawly.eu/ld/context.jsonld',
#     {
#         'name' => 'foaf:name',
#         'homepage' => {'@id' => 'http://xmlns.com/foaf/0.1/homepage', '@type' => '@id'},
#         'avatar' => {'@id' => 'http://xmlns.com/foaf/0.1/avatar', '@type' => '@id'}
#     }
# ]

#Knowledge repo
class MetadataHandler
  attr_reader :graph
  LAWLY_ROOT = 'http://rechtspraak.lawly.nl/'

  def initialize(xml, ecli)
    @triples = {}
    @xml = xml
    @ecli = ecli
    @rechtspraak_deeplink_uri = RDF::URI.new("#{RECHTSPRAAK_DEEPLINK_ROOT}/uitspraak?id=#{ecli}")
    @work_uri = RDF::URI.new("#{LAWLY_ROOT}id/#{ecli}")
    @meta_uri = RDF::URI.new("#{LAWLY_ROOT}id/#{ecli}:META")
    @doc_uri = RDF::URI.new("#{LAWLY_ROOT}id/#{ecli}:DOC")
    @graph = RDF::Graph.new
    extract_metadata
  end

  def create_typed_value(element_text, lang=nil)
    if element_text.match(/[A-Za-z]+:\/\//)
      RDF::URI.new(element_text)
    elsif element_text.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}/)
      RDF::Literal.new(element_text, :datatype => RDF::XSD.dateTime)
    elsif element_text.match(/[0-9]{4}-[0-9]{2}-[0-9]{2}/)
      RDF::Literal.new(element_text, :datatype => RDF::XSD.date)
    elsif lang
      RDF::Literal.new(element_text, :language => lang)
    else
      RDF::Literal.new(element_text)
    end
  end

  def to_json_ld
    context = [
        "http://assets.lawly.eu/ld/context.jsonld"
    ]

    JSON::LD::API::fromRdf(@graph) do |expanded|
      compacted = JSON::LD::API.compact(expanded, context)
      return compacted
    end

    nil
  end


  def self.shorten_http_prefix(uri)
    uri
    .gsub('http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'rdf:')
    .gsub('http://www.w3.org/2000/01/rdf-schema#', 'rdfs:')
    .gsub('http://purl.org/dc/terms/', 'dcterms:')
    .gsub('http://psi.rechtspraak.nl/', 'psi:')
    .gsub(/^bwb-dl$/, 'bwb:')
    .gsub('https://e-justice.europa.eu/ecli', 'ecli:')
    .gsub('http://decentrale.regelgeving.overheid.nl/cvdr/', 'cvdr:')
    .gsub('http://publications.europa.eu/celex/', 'eu:')
    .gsub('http://tuchtrecht.overheid.nl/', 'tr:')
  end

  def contract_uri(string)
    PREFIXES.each do |key_, val|
      key = key_.to_s
      if string.start_with? val
        return string.sub(val, "#{key}:")
      end
    end
  end

  def expand_prefix(string)
    PREFIXES.each do |key_, val|
      key = key_.to_s
      if string.start_with? key
        return string.sub(key, val)
      end
    end
    string
  end

  private
  def extract_metadata
    # Find <rdf:RDF>
    rdf_tag = @xml.xpath('/open-rechtspraak/rdf:RDF', PREFIXES)

    # Find all (two) <rdf:Description> tags
    metadata_tags = rdf_tag.xpath('./rdf:Description', PREFIXES)
    if metadata_tags.length < 2
      puts "ERROR: only found #{metadata_tags.length} metadata tags (expected 2)"
    else
      if metadata_tags.length > 2
        puts "WARNING: found #{metadata_tags.length} metadata tags (expected 2)"
      end
      handle_register_metadata(metadata_tags.first)
      handle_doc_metadata(metadata_tags.last)
    end

    # Add some more info
    # Work level
    add_statement(@work_uri, RDF::RDFV.type, RDF::URI.new('http://purl.org/vocab/frbr/core#LegalWork'))
    add_statement(@work_uri, RDF::OWL.sameAs, RDF::URI.new("http://deeplink.rechtspraak.nl/uitspraak?id=#{ecli}"))
    add_statement(@work_uri, RDF::URI.new('http://purl.org/vocab/frbr/core#realization'), @doc_uri)
    # TODO add foaf:page ... But to XML or JSON or HTML manifestation?

    # Expression level # TODO route expression uri to this data
    add_statement(@doc_uri, RDF::RDFV.type, RDF::URI.new('http://purl.org/vocab/frbr/core#Expression'))
    # TODO add manifestation
    # add_statement(@doc_uri,  RDF::URI.new('http://purl.org/vocab/frbr/core#embodiment'), )
    add_statement(@doc_uri, RDF::URI.new('http://purl.org/vocab/frbr/core#realizationOf'), @work_uri)
    # TODO add adaption/alternate
  end

  # Handle register metadata. This is generally metadata about the metadata / CMS.
  def handle_register_metadata(register_metadata)
    # ECLI id. We already have the id; irrelevant
    # handle_metadata(about, register_metadata, 'dcterms:identifier')

    # Doctype: text/xml; irrelevant, however might be interesting to embed in manifestations
    # handle_metadata(about, register_metadata, 'dcterms:format')

    # Same as document accessRights: fixed value of 'public'
    # handle_metadata(about, register_metadata, 'dcterms:accessRights')

    # Metadata last modified date
    handle_metadata(register_metadata, @meta_uri, RDF::DC.modified) # About the metadata

    # We only use issued from document metadata
    # handle_metadata(register_metadata, 'dcterms:issued')

    # We only use publisher from document metadata
    # handle_metadata(register_metadata, 'dcterms:publisher')

    # We only use language from document metadata
    # handle_metadata(register_metadata, 'dcterms:language')

    # LJN number
    handle_metadata(register_metadata, @work_uri, RDF::DC.replaces)
    # If the current ECLI is not valid, this points to a replacement ECLI. Note it's only about the identifier.
    handle_metadata(register_metadata, @work_uri, RDF::DC.isReplacedBy)
    # Judge
    handle_metadata(register_metadata, @work_uri, RDF::DC.contributor)
    # date of judgment
    handle_metadata(register_metadata, @work_uri, RDF::DC.date)
    # Add aliases
    handle_metadata(register_metadata, @work_uri, RDF::DC.alternative)
    # Ex: <psi:procedure rdf:language="nl"
    #      rdfs:label="Procedure"
    #      resourceIdentifier="http://psi.rechtspraak.nl/procedure#eersteAanlegMeervoudig">
    #       Eerste aanleg - meervoudig
    #     </psi:procedure>
    handle_metadata(register_metadata, @work_uri, RDF::URI.new('http://psi.rechtspraak.nl/procedure'))

    ##
    # Properties that need some custom processing:
    ##
    # URI for the court
    handle_creator(register_metadata)
    # 'Uitspraak' or 'Conclusie'
    handle_case_type(register_metadata)

    #"Indien sprake is van een afhankelijkheid van een specifieke periode waarbinnen de
    # betreffende zaak moet worden beoordeeld. Bijvoorbeeld in het geval van belasting
    # gerelateerde onderwerpen."
    #
    #handle_temporal(register_metadata)  # TODO 'dcterms:temporal'

    handle_references(register_metadata)
    # Jurisdiction
    handle_coverage(register_metadata)
    # Where versions of this judgment can be found. Might be different expressions (e.g., edited and annotated)
    handle_has_version(register_metadata)
    # Relations to other cases
    handle_relations(register_metadata)
    # Existing case numbers
    handle_case_numbers(register_metadata)
    # What kind of law this case is about (e.g., 'staatsrecht)
    handle_subject(register_metadata)
  end

  # Handle document metadata. This is generally metadata about the document.
  def handle_doc_metadata(xml_element)
    # ECLI id suffixed with :DOC; irrelevant
    # handle_metadata(text_document_metadata, 'dcterms:identifier')

    # handle_metadata(text_document_metadata, 'dcterms:format')  # 'text/html', irrelevant

    # Hardcoded 'public', some manifestations may be non-public. Like ones with their names unredacted.
    handle_metadata(xml_element, @work_uri, RDF::DC.accessRights)
    # Document modified
    handle_metadata(xml_element, @doc_uri, RDF::DC.modified)
    # Document publication date in YYYY-MM-DD
    handle_metadata(xml_element, @work_uri, RDF::DC.issued)
    handle_metadata(xml_element, @work_uri, RDF::DC.publisher) # Publisher
    handle_metadata(xml_element, @work_uri, RDF::DC.title) # Document title

    # Document language; already handled
    # handle_metadata(ml_converter, expression_uri, text_document_metadata, 'dcterms:language')

    # Short summary
    handle_abstract(xml_element)
  end

  # noinspection RubyStringKeysInHashInspection
  def handle_metadata(tree, subject, property_uri)
    elements = tree.xpath("./#{contract_uri(property_uri.to_s)}", PREFIXES)
    if !elements or elements.length <= 0
      # puts "Could not find #{verb} in #{tree.name}"
      return
    end

    # if elements.length > 1
    # found_more_msg = "Found #{elements.length} elements for #{verb} in #{@ecli}"
    # puts found_more_msg
    # end

    elements.each do |element|
      if element and element.element_children.length > 0
        puts "Found #{element.element_children.length} child nodes in tag for #{property_uri.to_s} in #{subject}"
      end

      # Human-readable label for the predicate
      predicate_label = nil
      if element['rdfs:label'] and element['rdfs:label'].strip.length > 0
        predicate_label = element['rdfs:label'].strip
      end

      if element['rdf:language'] and element['rdf:language'].strip.length>0
        language = element['rdf:language'].strip
      else
        language = nil
      end


      # Object URI
      resource_uri = nil
      if element['resourceIdentifier']
        # reference to uri
        str_resource_uri = expand_prefix(element['resourceIdentifier'])
        if str_resource_uri
          unless str_resource_uri.start_with? 'http'
            puts "WARNING: resource id is #{str_resource_uri.to_s}; did not start with http"
          end
          resource_uri = RDF::URI.new(str_resource_uri)
        end
      end

      # Inner text, either the object value or the object label
      if element.text.strip.length > 0
        element_text = element.text.strip
      else
        element_text = nil
      end

      # Decide how to structure the data
      if resource_uri
        # Use resource id as object and inner text as object label
        add_statement(subject, property_uri, resource_uri)
        if element_text
          add_statement(resource_uri, RDF::RDFS.label, element_text)
        end
      else # Use inner text as the object
        if element_text and element_text.length>0
          element_text = create_typed_value(element_text, language)
          add_statement(subject, property_uri, element_text)
        else
          puts "WARNING: No value found for #{verb}"
        end
      end

      if predicate_label # Add label for predicate
        add_statement(property_uri, RDF::RDFS.label, predicate_label)
      end
    end
  end

  def add_statement(s, p, o)
    @graph << RDF::Statement.new(s, p, o)
    # puts "Added new statement:"
    # puts RDF::Statement.new(s, p, o).inspect
  end


# Extract abstract. If the abstract has less than 2 characters, it's ignored
# Example:
#
# <dcterms:abstract>Bla Bla</dcterms:abstract>
#
# Becomes
#
# <uri> dcterms:abstract "Bla bla"^string
  def handle_abstract(tree)
    elements = tree.xpath("./dcterms:abstract", PREFIXES)
    predicate = RDF::DC.abstract
    if elements.length > 0
      if elements.length > 1
        puts "Found #{elements.length} elements for #{predicate} in #{@work_uri}"
      end

      elements.each do |element|
        abstract = element.text.strip # fallback if there's no resourceIdentifier
        if element['resourceIdentifier']
          inhoudsindicaties = @xml.xpath('/open-rechtspraak/rs:inhoudsindicatie', PREFIXES)
          if inhoudsindicaties.length > 0
            puts "WARNING: found #{inhoudsindicaties.length} inhoudsindicaties"
          end
          inhoudsindicaties.each do |inhoudsindicatie|
            abstract = inhoudsindicatie.text.strip
          end
        end
        if abstract and abstract.length > 1 # Don't add abstract if it's just a single character (most likely a dash), or nothing at all
          # NOTE: currently, abstract is just a string, but this may change to be a more intricate structure (with xml tags)
          add_statement(@work_uri, predicate, abstract)
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
  def handle_case_numbers(tree)
    elements = tree.xpath("./psi:zaaknummer", PREFIXES)
    predicate_uri = RDF::URI.new('http://psi.rechtspraak.nl/zaaknummer')
    # if elements.length > 1
    #   puts "Found #{elements.length} elements for #{predicate} in #{uri}"
    # end
    elements.each do |element|
      # A string like '97/8236 TW, 97/8241 TW' is probably two case numbers
      case_numbers = element.text.split(',')

      case_numbers.each do |case_number|
        trimmed = case_number.strip
        if trimmed.length > 0
          add_statement(@work_uri, predicate_uri, trimmed)
        end
      end
      if element['rdfs:label'] and element['rdfs:label'].strip.length > 0
        add_statement(predicate_uri, RDF::RDFS.label, element['rdfs:label'].strip)
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
  def handle_subject(tree)
    elements = tree.xpath("./dcterms:subject", PREFIXES)
    elements.each do |element|
      subjects = element.text.split(/;|,/)

      subjects.each do |subject|
        trimmed = subject.strip
        if trimmed.length > 0
          uri_obj = trimmed.downcase.gsub(' ', '_')
          object_uri = RDF::URI.new "#{LAWLY_ROOT}rechtsgebied/#{CGI.escape(uri_obj)}"
          add_statement(@work_uri, RDF::DC.subject, object_uri)
          add_statement(object_uri, RDF::RDFS.label, trimmed)
        end
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
  def handle_relations(tree)
    predicate_term = RDF::DC.relation

    elements = tree.xpath('./dcterms:relation', PREFIXES)
    for element in elements
      # Parse reference to ECLI
      referent_ecli = element['ecli:resourceIdentifier']
      referent_uri = RDF::URI.new("#{LAWLY_ROOT}id/#{referent_ecli}")
      # NOTE: documentation says 'typeRelatie'. But the data says 'type'
      relation_type = element['psi:type']
      unless relation_type and relation_type.length > 0
        relation_type = element['psi:typeRelatie']
      end
      relation_aanleg = element['psi:aanleg']

      # Create uri for this relation, in order to reify the statement
      relation_uri = RDF::Node.uuid

      # Build triple
      add_statement(relation_uri, RDF::RDFV.type, RDF::RDFV.Statement)
      add_statement(relation_uri, RDF::RDFV.subject, @work_uri)
      add_statement(relation_uri, RDF::RDFV.predicate, predicate_term)
      add_statement(relation_uri, RDF::RDFV.object, referent_uri)
      add_statement(@work_uri, predicate_term, referent_uri)

      # Add additional information about this triple
      relation_gevolg = element['psi:gevolg'] # "Het gevolg van de behandeling in latere aanleg."
      if relation_gevolg and relation_gevolg.strip.length > 0
        # Example:
        # http://psi.rechtspraak.nl/gevolg#(Gedeeltelijke) vernietiging en zelf afgedaan
        add_statement(relation_uri, RDF::URI.new('http://psi.rechtspraak.nl/gevolg'), create_typed_value(relation_gevolg.strip))
      end
      if relation_type and relation_type.strip.length > 0
        add_statement(relation_uri, RDF::URI.new('http://psi.rechtspraak.nl/typeRelatie'), create_typed_value(relation_type.strip))
      end
      if relation_aanleg and relation_aanleg.strip.length > 0
        add_statement(relation_uri, RDF::URI.new('http://psi.rechtspraak.nl/aanleg'), create_typed_value(relation_aanleg.strip))
      end

      # Human readable label for dc:relation
      predicate_label = element['rdfs:label']
      if predicate_label and predicate_label.strip.length > 0
        add_statement(predicate_term, RDF::RDFS.label, predicate_label.strip)
      end
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
  def handle_has_version(tree)
    predicate = 'dcterms:hasVersion'
    predicate_term = RDF::DC.hasVersion
    elements = tree.xpath("./#{predicate}", PREFIXES)
    if elements.length > 1
      puts "Found #{elements.length} elements for #{predicate} in #{@work_uri}"
    end
    elements.each do |has_version_element|
      item_lists = has_version_element.xpath('./rdf:list', PREFIXES)
      item_lists.each do |item_list|
        list_items = item_list.xpath('./rdf:li', PREFIXES)
        list_items.each do |item|
          add_statement(@work_uri, predicate_term, item.text)
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
# <subj_uri> dcterms:coverage "NL"
# This is/should be part of the hierarchy in the document work id: /country code/name of court/date or year/issue number/
  def handle_coverage(tree)
    predicate = 'dcterms:coverage'
    predicate_term = RDF::DC.coverage
    elements = tree.xpath("./#{predicate}", PREFIXES)
    if elements.length > 1
      puts "Found #{elements.length} elements for #{predicate} in #{@work_uri}"
    end


    elements.each do |element|
      jurisdiction = element.text
      unless jurisdiction.match /^http(s)?:\/\//
        jurisdiction = "#{LAWLY_ROOT}jurisdiction/#{jurisdiction}"
      end
      jurisdiction = create_typed_value jurisdiction
      add_statement(@work_uri, predicate_term, jurisdiction)
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
# TODO <uri> metalex:cites <http://doc.metalex.eu/id/BWBR0011823/artikel/59> ... ?
#
# NOTE: Discussed whether this should this references an *expression* of a law,
# because it refers to the law at a particular time (usually the time of the court case).
# I don't resolve the expression because we can't know with full certainty to what time it refers.
# It's rechtspraak.nl's responsibility to get the reference right anyway.
  def handle_references(tree)
    predicate = 'dcterms:references'
    elements = tree.xpath("./#{predicate}", PREFIXES)
    elements.each do |element|
      ## Gather info
      # Resource identifier
      doc_reference = nil
      doc_source_corpus = nil
      element.attributes.each do |name, attr|
        if name == 'resourceIdentifier' # Can be bwb:resourceIdentifier or cvdr:resourceIdentifier (for example in ECLI:NL:GHAMS:2014:1)
          case attr.namespace.prefix
            when 'bwb', 'cvdr'
            else
              puts "WARNING: Found ref with prefix #{attr.namespace.prefix} but did not know how to handle it"
          end
          doc_source_corpus = attr.namespace.prefix #e.g., 'bwb', 'cvdr'
          doc_reference = attr.value #identifier/juriconnect reference
        end
      end
      unless doc_reference
        puts 'could not find resource_id of this element:'
        puts element.to_s
        return
      end

      # TODO resolve identifier to URI if possible
      referent_node = RDF::Node.uuid

      doc_reference = create_typed_value(doc_reference.strip)
      add_statement(referent_node, RDF::DC.identifier, doc_reference)

      relation_node = RDF::Node.uuid
      # Create reified statement
      add_statement(relation_node, RDF::RDFV.type, RDF::RDFV.Statement)
      add_statement(relation_node, RDF::RDFV.subject, @work_uri)
      add_statement(relation_node, RDF::RDFV.predicate, RDF::DC.references)
      add_statement(relation_node, RDF::RDFV.object, referent_node)
      add_statement(@work_uri, RDF::DC.reference, referent_node)
      if element['rdfs:label'] and element['rdfs:label'].strip.length > 0
        #For example 'Wetsverwijzing'
        add_statement(relation_node, RDF::RDFS.label, element['rdfs:label'].strip)
      end
      # Name of the referent document
      ref_doc_name = element.text.strip
      if ref_doc_name.length>0
        add_statement(referent_node, RDF::RDFS.label, ref_doc_name)
      end
      add_statement(referent_node, RDF::DC.hasFormat, doc_source_corpus)

      # metalex_uri = get_target(resource_id)
      # if !target
      #   logging.warning("Did not find a resource identifier with '" + element.text + "'. Ignoring reference.")
      #   return
      # end
      # Go on if there's a metalex resource id
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
  def handle_creator(tree)
    predicate = 'dcterms:creator'
    predicate_term = RDF::DC.creator
    creators = tree.xpath("./#{predicate}", PREFIXES)
    creators.each do |creator|
      # A reference an OWMS uri (http://standaarden.overheid.nl/owms)
      court_uri = creator['resourceIdentifier']
      unless court_uri
        # If there's no OWMS uri, the site falls back to a psi.rechtspraak-prefixed uri
        court_uri = creator['psi:resourceIdentifier']
        unless court_uri
          puts "WARNING: Could not find a resourceIdentifier"
        end
      end
      tag_content = creator.text.strip

      if court_uri
        court_uri=create_typed_value(court_uri)
        add_statement(@work_uri, predicate_term, court_uri)

        # Give the court a human-readable name
        if tag_content.length > 0
          add_statement(court_uri, RDF::RDFS.label, tag_content)
        end
      else
        if tag_content.length > 0
          # Court only has a string name, no http uri
          add_statement(@work_uri, predicate_term, tag_content)
          puts "WARNING: Court #{tag_content} only has a string name, no http uri"
        else
          puts 'WARNING: Court has no name, and no http uri'
        end
      end

      # The relation has a human-readable label
      if creator['rdfs:label'] and creator['rdfs:label'].strip.length > 0
        add_statement(predicate_term, RDF::RDFS.label, creator['rdfs:label'].strip)
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
  def handle_case_type(tree)
    predicate = 'dcterms:type'
    types = tree.xpath("./#{predicate}", PREFIXES)
    types.each do |type| # Should be just 1
      type_uri = type['resourceIdentifier']
      if type_uri and type_uri.strip.length > 0
        type_uri = RDF::URI(type_uri)
        add_statement(@work_uri, RDF::DC.type, type_uri)

        label = type.text.strip
        if label.length > 0
          add_statement(type_uri, RDF::RDFS.label, label)
        end
      end
    end
  end

end