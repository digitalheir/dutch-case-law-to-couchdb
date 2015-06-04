require 'base64'
require 'time'
require_relative '../rechtspraak-nl/rechtspraak_utils'
require_relative '../converter/metadata_handler_jsonld'
include RechtspraakUtils
# noinspection RubyStringKeysInHashInspection
class RechtspraakExpressionTokenized
  JSON_LD_URI = 'http://assets.lawly.eu/ld/context.jsonld'
  XSLT_TO_TXT = Nokogiri::XSLT(File.read('converter/xslt/rechtspraak_to_txt.xslt'))
  XSLT_TO_HTML = Nokogiri::XSLT(File.read('converter/xslt/rechtspraak_to_html.xslt'))

  attr_reader :doc
  # Initializes a new CouchDB document for a case law expression.
  # Only processes metadata; source docs are added in add_attachments.
  def initialize(doc, original_xml)
    @doc = doc
    add_attachments(original_xml)
  end

  private

  # These attachments may or may not be available in the future, but currently not added due to space limitations.
  #
  # - metalex.xml can be generated through the web service
  def add_attachments xml
    @doc['_attachments'] ||= {}
    str_xml = xml.to_s

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

    html = XSLT_TO_HTML.transform(xml).to_s
    @doc['_attachments']['data.htm'] = {
        content_type: 'text/html',
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

  private
  def tokenize str
    File.write('tmp.txt', str)
    str = `$ALPINO_HOME/Tokenization/paragraph_per_line tmp.txt | $ALPINO_HOME/Tokenization/tokenize.sh`
    str.split(/\r?\n/).map { |s| s.split(' ') }
  end
end
