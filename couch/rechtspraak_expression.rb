require 'base64'
require 'time'
require_relative '../rechtspraak-nl/rechtspraak_utils'
require_relative '../converter/metadata_handler_jsonld'
include RechtspraakUtils
# noinspection RubyStringKeysInHashInspection
class RechtspraakExpression
  JSON_LD_URI = 'https://rechtspraak.cloudant.com/assets/assets/context.jsonld'
  XSLT_TO_TXT = Nokogiri::XSLT(File.read('../converter/xslt/rechtspraak_to_txt.xslt'))
  XSLT_TO_HTML = Nokogiri::XSLT(File.read('../converter/xslt/rechtspraak_to_html.xslt'))

  attr_reader :doc
  # Initializes a new CouchDB document for a case law expression.
  # Only processes metadata; source docs are added in add_attachments.
  def initialize(ecli, original_xml)
    @doc = {
        '_id' => ecli,
        'ecli' => ecli,
        'corpus' => 'Rechtspraak.nl',
        '@context' => JSON_LD_URI,
        'dcterms:source' => "http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}",
        'markedUpByRechtspraak' => has_rich_markup(original_xml)
    }

    #??? @doc['@type'] = 'frbr:Expression'
    add_metadata(ecli, original_xml)
    now = (Time.now+(48*60*60)).getutc.iso8601
    @doc['couchDbUpdated']=now
    add_attachments(original_xml)
  end

  private

  # These attachments may or may not be available in the future, but currently not added due to space limitations.
  #
  # - metalex.xml can be generated through the web service
  def add_attachments xml
    @doc['_attachments'] ||= {}
    str_xml = xml.to_s
    @doc['_attachments']['data.xml'] = {
        content_type: 'text/xml;charset=utf-8',
        data: Base64.encode64(str_xml)
    }

    html = XSLT_TO_HTML.transform(xml).to_s.force_encoding('utf-8')
    @doc['_attachments']['data.htm'] = {
        content_type: 'text/html;charset=utf-8',
        data: Base64.encode64(html)
    }
  end

  def shorten_http_prefix(property)
    property
        .gsub('http://www.w3.org/1999/02/22-rdf-syntax-ns#', 'rdf:')
        .gsub('http://www.w3.org/2000/01/rdf-schema#', 'rdfs:')
        .gsub('http://purl.org/dc/terms/', 'dcterms:')
        .gsub('http://psi.rechtspraak.nl/', 'psi:')
        .gsub('bwb-dl', 'bwb:')
        .gsub('https://e-justice.europa.eu/ecli', 'ecli:')
        .gsub('http://decentrale.regelgeving.overheid.nl/cvdr/', 'cvdr:')
        .gsub('http://publications.europa.eu/celex/', 'eu:')
        .gsub('http://tuchtrecht.overheid.nl/', 'tr:')
  end


  def add_metadata(ecli, xml)
    metadata_handler = MetadataHandlerJsonLd.new(xml, ecli)
    @doc.merge! metadata_handler.metadata
  end
end
