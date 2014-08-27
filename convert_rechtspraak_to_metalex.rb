require 'nokogiri'
require 'json'
require 'open-uri'
require_relative 'metalex_converter/rechtspraak_to_metalex_converter'

mapping = JSON.parse open('rechtspraak_mapping.json').read
converter = RechtspraakToMetalexConverter.new(mapping)
files = Dir['rich/*']
xsd = Nokogiri::XML::Schema(open('e.xsd').read)
i=0
files.each do |path|
  # xml = Nokogiri::XML File.open(path)
  #
  #   #Convert doc
  #   converter.start(xml, ecli,dfkdsjfn)
  #
  #   xml = Nokogiri::XML root.to_s
  #   # puts root
  #   # puts xml
  #   has_error = false
  #   xsd.validate(xml).each do |error|
  #     puts error.message
  #     has_error = true
  #   end
  #   if has_error
  #     puts ''
  #     puts xml
  #   end
  # end
  # # break
  # i+=1
  # if i%100==0
  # puts i
  #   end
end