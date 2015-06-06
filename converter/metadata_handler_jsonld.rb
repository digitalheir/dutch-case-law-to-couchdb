# Extracts and enhances metadata as JSON-LD / RDF
require 'cgi'
require 'set'
require 'rdf'
require 'json/ld'

# noinspection RubyStringKeysInHashInspection,RubyTooManyMethodsInspection
class MetadataHandlerJsonLd
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

  RECHTSPRAAK_DEEPLINK_ROOT = 'http://deeplink.rechtspraak.nl'


  PREFIXES = {:rdf => NS_RDF, :rdfs => NS_RDFS, :dcterms => NS_DCTERMS, :psi => NS_PSI, :rs => NS_RS}

  attr_reader :metadata
  LAWLY_ROOT = 'http://rechtspraak.lawreader.eu/'

  def initialize(xml, ecli)
    @xml = xml
    @ecli = ecli
    @metadata = {}
    @context_mapping = {

    }
    extract_metadata
    @metadata['@context'] = [
        'http://rechtspraak.cloudant.com/assets/assets/context.jsonld',
        @context_mapping
    #TODO add url prefixes from xml that are not in context (if any!)
    ]
  end

  def contract_uri(string)
    #TODO use @prefix, where @prefix is defined with with prefixes found in XML
    PREFIXES.each do |key_, val|
      key = key_.to_s
      if string.start_with? val
        return string.sub(val, "#{key}:")
      end
    end
    string
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
    # First handle fields that may appear in any of both Description tags
    handle_global_metadata(rdf_tag)
    # Find all (two) <rdf:Description> tags
    handle_manifestation_metadata(rdf_tag)

    # Add some more info
    set_property('@type', 'frbr:LegalWork')
    set_property('_id', @ecli)
    set_property('owl:sameAs', "http://deeplink.rechtspraak.nl/uitspraak?id=#{@ecli}")
    set_property('foaf:page', "http://rechtspraak.lawly.nl/ecli/#{@ecli}")
    # TODO add adaption/alternate
  end

  def handle_manifestation_metadata(rdf_tag)
    metadata_tags = rdf_tag.xpath('./rdf:Description', PREFIXES)
    if metadata_tags.length < 2
      # puts "WARNING: only found #{metadata_tags.length} metadata tags in #{@ecli} (expected 2)"
      if metadata_tags.first
        if metadata_tags.first['rdf:about']
          handle_doc_metadata(metadata_tags.first)
        else
          handle_register_metadata(metadata_tags.first)
        end
      end
    else
      if metadata_tags.length > 2
        puts "WARNING: found #{metadata_tags.length} metadata tags in #{@ecli} (expected 2)"
      end
      handle_register_metadata(metadata_tags.first)
      handle_doc_metadata(metadata_tags.last)
    end
  end

  # noinspection RubyResolve
  def handle_global_metadata(xml_element)
    # Hardcoded 'public', some manifestations may be non-public. Like ones with their names unredacted.
    handle_single_resource(xml_element, RDF::DC.accessRights) # Fixed to 'public'
    handle_single_resource(xml_element, RDF::DC.publisher) # Publisher
    handle_single_literal(xml_element, RDF::DC.title) # Document title
    handle_single_resource(xml_element, RDF::DC.language) # Fixed to 'nl'
    handle_abstract(xml_element) # Short summary, needs special handling for dashes

    handle_literal_list(xml_element, RDF::DC.replaces) # LJN number
    handle_single_literal(xml_element, RDF::DC.isReplacedBy) # If the current ECLI is not valid, this points to a replacement ECLI. Note it's only about the identifier.
    handle_resource_list(xml_element, RDF::DC.contributor) # Judge
    handle_single_literal(xml_element, RDF::DC.date) # date of judgment
    handle_literal_list(xml_element, RDF::DC.alternative) # Add aliases / alternative titles

    # Ex; 0 or more: <psi:procedure rdf:language="nl"
    #      rdfs:label="Procedure"
    #      resourceIdentifier="http://psi.rechtspraak.nl/procedure#eersteAanlegMeervoudig">
    #       Eerste aanleg - meervoudig
    #     </psi:procedure>
    handle_resource_list(xml_element, RDF::URI.new('http://psi.rechtspraak.nl/procedure'))
    handle_creator(xml_element) #Court resource
    handle_single_resource(xml_element, RDF::DC.type) # 'Uitspraak' or 'Conclusie'
    #"Indien sprake is van een afhankelijkheid van een specifieke periode waarbinnen de
    # betreffende zaak moet worden beoordeeld. Bijvoorbeeld in het geval van belasting
    # gerelateerde onderwerpen."
    handle_temporal(xml_element)
    handle_references(xml_element)
    handle_coverage(xml_element) # Jurisdiction
    handle_has_version(xml_element) # Where versions of this judgment can be found. Might be different expressions (e.g., edited and annotated)
    handle_relations(xml_element) # Relations to other cases
    handle_case_numbers(xml_element) # Existing case numbers
    handle_subject(xml_element) # What kind of law this case is about (e.g., 'staatsrecht)
  end


  # Handle register metadata. This is generally metadata about the metadata / CMS.
  # noinspection RubyResolve
  def handle_register_metadata(register_metadata)
    # ECLI id. We already have the id; irrelevant
    # handle_metadata(about, register_metadata, 'dcterms:identifier')

    # Doctype: text/xml; irrelevant, however might be interesting to embed in manifestations
    # handle_metadata(about, register_metadata, 'dcterms:format')

    # Metadata last modified date
    handle_metadata_modified(register_metadata) # About the metadata

    # XML publication date in YYYY-MM-DD
    handle_single_literal(register_metadata, RDF::DC.issued)
  end


  def handle_temporal(element)
    temporal = element.at_xpath './/dcterms:temporal', PREFIXES
    return unless temporal
    el_start = temporal.at_xpath './start', PREFIXES
    el_end = temporal.at_xpath './end', PREFIXES
    unless el_start and el_end
      puts " WARNING: dcterms:temporal was not well formed for #{@ecli}"
      return
    end
    set_uri_mapping('Periode', 'dcterms:temporal')
    set_property('dcterms:temporal', {
                                       '@type' => 'dcterms:PeriodOfTime',
                                       'schema:startDate' => el_start.text.strip,
                                       'schema:endDate' => el_end.text.strip
                                   })
  end

  # Handle document metadata. This is generally metadata about the document.
  # noinspection RubyResolve
  def handle_doc_metadata(xml_element)
    unless xml_element['rdf:about']
      puts "WARNING: metadata block for #{@ecli} didn't have rdf:about"
    end
    handle_html_publication(xml_element) # HTML publication date in YYYY-MM-DD
    handle_single_literal(xml_element, RDF::DC.modified) # Document modified
    # ECLI id suffixed with :DOC; irrelevant
    # handle_metadata(text_document_metadata, 'dcterms:identifier')
    # handle_metadata(text_document_metadata, 'dcterms:format')  # 'text/html', irrelevant
  end

  # noinspection RubyStringKeysInHashInspection
  def handle_resource_list(tree, property_uri)
    property_uri=property_uri.to_s
    field = contract_uri(property_uri)
    elements = tree.xpath(".//#{field}", PREFIXES)
    if !elements or elements.length <= 0
      return
    end
    if property_uri.to_s == RDF::DC.contributor.to_s
      puts
    end

    predicate_value_map = {}
    elements.each do |element|
      language, predicate_label, resource_uri, value_label = get_element_data(element, property_uri)
      # Decide what to use for value
      value = create_value_map(resource_uri, value_label, language)

      if predicate_label
        set_uri_mapping(predicate_label, property_uri)
      end
      predicate_value_map[field] ||= []
      predicate_value_map[field] << value
    end

    predicate_value_map.each do |pred, values|
      if values
        set_property(pred, values)
      end
    end
  end

  # noinspection RubyStringKeysInHashInspection
  def handle_literal_list(tree, property_uri)
    property_uri=property_uri.to_s
    field = contract_uri(property_uri.to_s)
    elements = tree.xpath(".//#{field}", PREFIXES)
    if !elements or elements.length <= 0
      return
    end
    if property_uri == RDF::DC.alternative.to_s
      puts
    end

    predicate_value_map = {}
    elements.each do |element|
      _, predicate_label, _, value_label = get_element_data(element, property_uri)
      # Decide what to use for value
      value = value_label

      if predicate_label
        set_uri_mapping(predicate_label, property_uri)
      end
      predicate_value_map[field] ||= []
      predicate_value_map[field] << value
    end

    predicate_value_map.each do |pred, values|
      if values
        set_property(pred, values)
      end
    end
  end

  def get_element_data(element, predicate_uri)
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
      # str_resource_uri = expand_prefix(element['resourceIdentifier'])
      str_resource_uri = element['resourceIdentifier']
      if str_resource_uri
        unless str_resource_uri.start_with? 'http'
          puts "WARNING: resource id is #{str_resource_uri.to_s}; did not start with http"
        end
        resource_uri = str_resource_uri
      end
    end

    # Inner text, either the object value or the object label
    if element.text.strip.length > 0
      value_label = element.text.strip
    else
      value_label = nil
    end
    if !resource_uri and value_label
      resource_uri=create_uri_from_label(contract_uri(predicate_uri), value_label, true)
    end
    if value_label
      case value_label
        when /^http/
          puts "WARNING: element text is URI: #{value_label} (#{@ecli})"
          resource_uri = value_label unless resource_uri
          value_label = nil
        when 'nl'
          if RDF::DC.language.to_s == predicate_uri
            value_label = 'Nederlands'
            language = 'nl'
          end
        else
      end
    end
    if !value_label and resource_uri
      # Create label from uri
      value_label = create_label_from_uri(resource_uri)
    end
    if !value_label or !resource_uri
      puts "WARNING: no value label or resource uri (#{@ecli})"
    end
    return language, predicate_label, resource_uri, value_label
  end

  def create_value_map(resource_uri, value_label, language=nil)
    value = {}
    label={'@value' => value_label}
    if language and language.strip.length > 0
      label['@language']=language
    end
    value['rdfs:label']=[label]
    value['@id']=resource_uri
    value
  end

  def handle_single_resource(tree, property_uri)
    property_uri=property_uri.to_s
    element = tree.at_xpath(".//#{contract_uri(property_uri.to_s)}", PREFIXES)
    unless element
      return # Not found in tree
    end
    language, predicate_label, resource_uri, value_label = get_element_data(element, property_uri)
    # Decide what to use for value
    value = create_value_map(resource_uri, value_label, language)
    if predicate_label
      set_uri_mapping(predicate_label, property_uri)
    end
    set_property(property_uri, value)
  end

  def handle_html_publication(tree)
    elements = tree.xpath('./dcterms:issued', PREFIXES)
    if elements and elements.length > 0
      issued = elements.first.text.strip
      set_property('htmlIssued', issued) if issued.length > 0
    end
  end


  def create_label_from_uri(uri)
    match = /http:.*\/(.*)\/?$/.match(uri.strip.sub(/\/$/, ''))
    if match and match[1]
      match[1].gsub(/(%20|_)/, ' ').capitalize
    else
      uri
    end
  end

  def set_uri_mapping(label, mapping_uri)
    map = mapping_uri

    if @context_mapping[label] and @context_mapping[label] != map
      puts "WARNING: #{label} already has mapping #{@context_mapping[label]} (#{@ecli})"
    end
    @context_mapping[label] = map
  end

  def set_property(p, o)
    p=contract_uri(p)
    if @metadata[p] and @metadata[p] != o
      puts "WARNING: #{p} already has value #{@metadata[p]} (#{@ecli})"
    end
    @metadata[p] = o
    # puts "Added new statement: #{p}: #{o}"
  end


  def handle_single_literal(tree, property)
    prop_name = contract_uri(property.to_s)
    elements = tree.xpath(".//#{prop_name}", PREFIXES)
    if elements.length > 0
      elements.each do |element|
        set_property(prop_name, element.text.strip)
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
  def handle_abstract(tree)
    elements = tree.xpath('.//dcterms:abstract', PREFIXES)
    if elements.length > 0
      elements.each do |element|
        abstract = element.text.strip # fallback if there's no resourceIdentifier
        if element['resourceIdentifier']
          inhoudsindicaties = @xml.xpath('/open-rechtspraak/rs:inhoudsindicatie', PREFIXES)
          if inhoudsindicaties.length > 1
            puts "WARNING: found #{inhoudsindicaties.length} inhoudsindicaties"
          end
          inhoudsindicaties.each do |inhoudsindicatie|
            abstract = inhoudsindicatie.text.strip
          end
        end
        if abstract and abstract.length > 1 # Don't add abstract if it's just a single character (most likely a dash), or nothing at all
          # NOTE: currently, abstract is just a string, but this may change to be a more intricate structure (with xml tags)
          set_property('dcterms:abstract', abstract)
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
    elements = tree.xpath('.//psi:zaaknummer', PREFIXES)
    # if elements.length > 1
    #   puts "Found #{elements.length} elements for #{predicate} in #{uri}"
    # end
    trimmed_case_numbers = Set.new
    elements.each do |element|
      # A string like '97/8236 TW, 97/8241 TW' is probably two case numbers
      case_numbers = element.text.split(',')

      case_numbers.each do |case_number|
        trimmed = case_number.strip
        if trimmed.length > 0
          trimmed_case_numbers << trimmed
        end
      end
      if element['rdfs:label'] and element['rdfs:label'].strip.length > 0
        set_uri_mapping(element['rdfs:label'].strip, 'psi:zaaknummer')
      end
    end
    if trimmed_case_numbers.length > 0
      set_property('psi:zaaknummer', trimmed_case_numbers.to_a)
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
    elements = tree.xpath('.//dcterms:subject', PREFIXES)
    all_subjects = Set.new
    elements.each do |element|
      subjects = element.text.split(/;|,/)

      subjects.each do |subject|
        trimmed = subject.strip
        if trimmed.length > 0
          uri_obj = trimmed.downcase.gsub(' ', '_')
          object_uri = "#{LAWLY_ROOT}rechtsgebied/#{CGI.escape(uri_obj)}"
          all_subjects << create_value_map(object_uri, trimmed, nil)
        end
      end
    end
    set_property('dcterms:subject', all_subjects.to_a)
  end


  def handle_metadata_modified(tree)
    elements = tree.xpath('./dcterms:modified', PREFIXES)
    elements.each do |element|
      modified = element.text.strip
      set_property('metadataModified', modified)
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
    relation_infos=[]
    elements = tree.xpath('.//dcterms:relation', PREFIXES)
    elements.each { |element|
      # Parse reference to ECLI
      referent_ecli = element['ecli:resourceIdentifier']
      # NOTE: documentation says 'typeRelatie'. But the data says 'type'
      relation_type = element['psi:type']
      unless relation_type and relation_type.length > 0
        relation_type = element['psi:typeRelatie']
      end
      relation_aanleg = element['psi:aanleg']

      # Create uri for this relation, in order to reify the statement
      # Build triple
      relation_info={
          '@id' => "http://www.lawreader.eu/ref/ecli/#{referent_ecli}",
      }

      # Add additional information about this triple # TODO validate if values are URIs; create URI mapping.
      relation_gevolg = element['psi:gevolg'] # "Het gevolg van de behandeling in latere aanleg."
      if relation_gevolg and relation_gevolg.strip.length > 0
        # Example:
        # http://psi.rechtspraak.nl/gevolg#(Gedeeltelijke) vernietiging en zelf afgedaan
        relation_info['psi:gevolg']= relation_gevolg.strip
      end
      if relation_type and relation_type.strip.length > 0
        relation_info['psi:typeRelatie']= relation_type.strip
      end
      if relation_aanleg and relation_aanleg.strip.length > 0
        relation_info['psi:aanleg']= relation_aanleg.strip
      end
      if element.text.strip and element.text.strip.length > 0
        relation_info['rdfs:label']=element.text.strip
      end

      # Human readable label for dc:relation
      predicate_label = element['rdfs:label']
      if predicate_label and predicate_label.strip.length > 0
        set_uri_mapping(predicate_label, 'dc:relation')
      end

      relation_infos << relation_info
    }
    if relation_infos and relation_infos.length > 0
      set_property('dcterms:relation', relation_infos)
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
  def handle_has_version(tree)
    predicate = 'dcterms:hasVersion'
    sources = []
    elements = tree.xpath(".//#{predicate}", PREFIXES)
    if elements.length > 1
      puts "Found #{elements.length} elements for #{predicate} in #{@ecli}"
    end
    elements.each do |has_version_element|
      item_lists = has_version_element.xpath('./rdf:list', PREFIXES)
      item_lists.each do |item_list|
        list_items = item_list.xpath('./rdf:li', PREFIXES)
        list_items.each do |item|
          sources << create_value_map(create_uri_from_label('source', item.text.strip, false, false), item.text.strip)
        end
      end
    end
    set_property(predicate, sources)
  end

  def create_uri_from_label(subdir, id, normalize_id=true, as_parameter=false)
    if subdir.match /^[^:]+:([^:]+)$/
      subdir = $1
    end
    if normalize_id
      id = id.downcase.gsub(/[^a-z0-9-]/, '_')
    end
    if as_parameter
      "#{CGI.escape(subdir)}?p=#{CGI.escape(id)}"
    else
      "#{CGI.escape(subdir)}/#{CGI.escape(id)}"
    end
  end

  # Example:
  #
  # <dcterms:coverage>NL</dcterms:coverage>
  #
  # Becomes:
  #
  # <subj_uri> dcterms:coverage "NL"
  # Fixed value. This is/should be part of the hierarchy in the document work id: /country code/name of court/date or year/issue number/
  def handle_coverage(tree)
    predicate = 'dcterms:coverage'
    element = tree.xpath(".//#{predicate}", PREFIXES)
    return unless element
    jurisdiction_code = element.text
    case jurisdiction_code
      when 'NL'
        value_label='Nederland'
      else
        value_label=jurisdiction_code
    end
    jurisdiction_uri = create_uri_from_label('jurisdiction', jurisdiction_code, true)
    set_property(predicate, create_value_map(jurisdiction_uri, value_label, 'nl'))
  end

  # Example:
  #
  # <dcterms:references
  #   rdfs:label="Wetsverwijzing"
  #   bwb:resourceIdentifier="1.0:v:BWB:BWBR0011823&artikel=59">
  #     Vreemdelingenwet 2000 59
  # </dcterms:references>
  #
  # NOTE: Discussed whether this should this references an *expression* of a law,
  # because it refers to the law at a particular time (usually the time of the court case).
  # I don't resolve the expression because we can't know with full certainty to what time it refers.
  # It's rechtspraak.nl's responsibility to get the reference right anyway.
  def handle_references(tree)
    predicate = 'dcterms:references'
    reference_infos=[]
    elements = tree.xpath(".//#{predicate}", PREFIXES)
    elements.each do |element|
      ## Gather info
      # Resource identifier
      reference_id = nil
      doc_source_corpus = nil
      element.attributes.each do |name, attr|
        if name == 'resourceIdentifier' # Can be bwb:resourceIdentifier or cvdr:resourceIdentifier (for example in ECLI:NL:GHAMS:2014:1)
          case attr.namespace.prefix
            when 'bwb'
            when 'cvdr'
            else
              puts "WARNING: Found ref with prefix #{attr.namespace.prefix} but did not know how to handle it"
          end


          doc_source_corpus = attr.namespace.prefix #e.g., 'bwb', 'cvdr'
          reference_id = attr.value #identifier/juriconnect reference
        end
      end
      unless reference_id
        puts 'could not find resource_id of this element:'
        puts element.to_s
        return
      end
      reference_id.strip!

      if doc_source_corpus
        id = "http://www.lawreader.eu/ref/#{doc_source_corpus}/#{reference_id}"
      else
        id = "http://www.lawreader.eu/ref/#{reference_id}"
      end
      reference = {
          '@id' => id,
          'dcterms:identifier' => reference_id,
          'dcterms:isReferencedBy' => "http://rechtspraak.lawreader.eu/id/#{@ecli}",
          'dcterms:hasFormat' => doc_source_corpus,
      }
      # Create reified statement
      if element['rdfs:label'] and element['rdfs:label'].strip.length > 0
        # For example 'Wetsverwijzing'
        label = element['rdfs:label'].strip
        reference['lawly:referenceType'] = {}
        reference['lawly:referenceType']['rdfs:label'] = [{'@value' => label}]
        reference['lawly:referenceType']['@id'] = label.downcase
      end
      # Name of the referent document
      ref_doc_name = element.text.strip
      if ref_doc_name.length>0
        reference['dcterms:title'] = ref_doc_name
      end
      reference_infos << reference
    end
    if reference_infos.length > 0
      set_property(predicate, reference_infos)
    end
  end

  # Cardinality of 1. Example:
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
    #TODO handle scheme........? (28-5-2015: what scheme?)
    creator_element = tree.at_xpath('.//dcterms:creator', PREFIXES)
    # A reference an OWMS uri (http://standaarden.overheid.nl/owms)

    unless creator_element
      raise "ERROR: #{@ecli} did not have a creator"
      # return
    end
    court_name = creator_element.text.strip
    court_uri = creator_element['resourceIdentifier']
    unless court_uri
      # If there's no OWMS uri, the site falls back to a psi.rechtspraak-prefixed uri
      court_uri = creator_element['psi:resourceIdentifier']
      unless court_uri
        puts 'WARNING: Could not find a resourceIdentifier'
        court_uri = create_uri_from_label('creator', court_name, true)
      end
    end

    unless court_uri and court_uri.length > 0
      puts "WARNING: Court #{court_name} doesn't have a http uri"
      court_uri = create_uri_from_label('court', court_name, true)
    end
    unless court_name and court_name.length > 0
      puts "WARNING: Court #{court_uri} doesn't have a name"
      court_name = create_label_from_uri(court_uri)
    end
    set_property('dcterms:creator', create_value_map(court_uri, court_name))

    # The relation has a human-readable label
    if creator_element['rdfs:label'] and creator_element['rdfs:label'].strip.length > 0
      set_uri_mapping(creator_element['rdfs:label'].strip, 'dcterms:creator')
    end
  end

end