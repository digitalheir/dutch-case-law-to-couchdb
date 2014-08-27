# Script to convert rechtspraak documents to Metalex standard

require 'nokogiri'
require 'json'
require 'open-uri'
require_relative 'metalex_converter/rechtspraak_to_metalex_converter'
require_relative 'metalex_converter/metadata_handler'


FOLDER='rich'
mapping = JSON.parse open('metalex_converter/rechtspraak_mapping.json').read
converter = RechtspraakToMetalexConverter.new(mapping)
files = Dir["#{FOLDER}/*"]
xsd = Nokogiri::XML::Schema(open('metalex_converter/e.xsd').read)
i=0

files.each do |path|
  xml = Nokogiri::XML File.open(path)

  #Convert doc
  identifiers = xml.xpath('/open-rechtspraak/rdf:RDF/rdf:Description/dcterms:identifier', PREFIXES)
  ecli = identifiers.first.text.strip
  xml = converter.start(xml, ecli)

  has_error = false
  xml = Nokogiri::XML xml.to_s # build a new xml doc because validation doesnt work otherwise
  xsd.validate(xml).each do |error|
    puts error.message
    has_error = true
  end
  if has_error
    puts ''
    puts xml
  end
end
# break
i+=1
if i%100==0
  puts "Processed #{i} documents"
end