require 'nokogiri'
require 'json'
require_relative 'rechtspraak_to_metalex_converter'

mapping = JSON.parse open('rechtspraak_mapping.json').read
converter = RechtspraakToMetalexConverter.new(mapping)
files = Dir['rich/*']
files.each do |path|
  xml = Nokogiri::XML File.open(path)

  # The rechtspraak docs have metadata in them, but we want an XML doc out of the actual content. So first get the content root node.
  roots = xml.xpath '/open-rechtspraak/rs:conclusie|/open-rechtspraak/rs:uitspraak', {:rs => 'http://www.rechtspraak.nl/schema/rechtspraak-1.0'}
  if roots.length != 1
    raise "Found #{roots.length} roots in #{path}"
  else
    root = roots.first

    #Convert doc
    converter.start(root)

    puts root
  end
  break
end