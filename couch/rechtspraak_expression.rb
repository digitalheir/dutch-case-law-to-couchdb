require 'base64'
require 'time'
require_relative '../rechtspraak-nl/rechtspraak_utils'
require_relative '../converter/metadata_handler_jsonld'
include RechtspraakUtils
# noinspection RubyStringKeysInHashInspection
class RechtspraakExpression
  JSON_LD_URI = 'http://assets.lawly.eu/ld/context.jsonld'
  XSLT_TO_TXT = Nokogiri::XSLT(File.read('../converter/xslt/rechtspraak_to_txt.xslt'))

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
    add_attachments original_xml
    @doc['couchDbUpdated']=Time.now.getutc.iso8601
  end

  private

  # These attachments may or may not be available in the future, but currently not added due to space limitations.
  #
  # - metalex.xml can be generated through the web service
  def add_attachments xml
    @doc['_attachments'] ||= {}
    str_xml = xml.to_s
    @doc['_attachments']['data.xml'] = {
        content_type: 'text/xml',
        data: Base64.encode64(str_xml)
    }

    plaintext = XSLT_TO_TXT.transform(xml).to_s.sub(/^<\?[\s]*xml[^>]*\?>/, '')
    @doc[:tokens] = tokenize(plaintext.gsub(/^[\s]+/, ''))

    tag_regex = /<[^>]*>/
    @doc['_attachments']['data.txt'] = {
        content_type: 'text/plain;charset=utf-8',
        data: Base64.encode64(str_xml.gsub(tag_regex, ''))
    }

    tag_positions = str_xml.enum_for(:scan, tag_regex).map do
      {
          string: Regexp.last_match.to_s,
          begin: Regexp.last_match.begin(0),
          end: Regexp.last_match.end(0)
      }
    end

    @doc['_attachments']['tag_locations.json'] = {
        content_type: 'text/json',
        data: Base64.encode64(tag_positions.to_json)
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

  private
  def tokenize str
    File.write('tmp.txt', str)
    str = `$ALPINO_HOME/Tokenization/paragraph_per_line tmp.txt | $ALPINO_HOME/Tokenization/tokenize.sh`
    str.split(/\r?\n/).map() { |s| s.split(' ') }
  end
end
