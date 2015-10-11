# Script that kickstarts the metalex conversion mapping

require 'nokogiri'
require 'set'
require 'json'

# add element names recursively to given set
def add_elements set, root
  set << root.name
  root.children.each do |child|
    add_elements set, child
  end
end

files = Dir['rich/*']
elements = Set.new
i=0
files.each do |path|
  xml = Nokogiri::XML File.open(path)
  roots = xml.xpath '/open-rechtspraak/rs:conclusie|/open-rechtspraak/rs:uitspraak', {:rs => 'http://www.rechtspraak.nl/schema/rechtspraak-1.0'}
  if roots.length != 1
    puts "WARNING: Found #{roots.length} roots"
  else
    root = roots.first
    add_elements elements, root
    elements.add root.name
  end
  # puts path
  i+=1
  if i%1000 == 0
    puts "Looked at #{i} files"
  end
  # break
end

puts "Found #{elements.length} unique elements"

# Generate mapping file in JSON
mapping = {}
elements.each do |name|
  if name == 'conclusie' or name == 'uitspraak'
    mapping[name] = 'container'
  else
    mapping[name] = 'inline'
  end
end

# Serialize mapping as JSON file
File.open('rechtspraak_mapping.json', 'w+') do |file|
  file.puts JSON.pretty_generate(mapping)
end

## Generate xsd document
# schema = Nokogiri::XML '<?xml version="1.0" encoding="UTF-8"?>
# <xs:schema xmlns:metalex="http://www.metalex.eu/metalex/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" elementFormDefault="qualified" attributeFormDefault="unqualified">
#   <xs:import namespace="http://www.metalex.eu/metalex/1.0"
#               schemaLocation="http://justinian.leibnizcenter.org/MetaLex/e.xsd"/>
# </xs:schema>'
# elements.each do |element_name|
#   element = Nokogiri::XML::Node.new 'xs:element', schema
#   element['name'] = element_name
#   element['type'] = "metalex:blockType"
#   schema.root.add_child '
#     '
#   schema.root.add_child element
#   end
# schema.root.add_child '
# '
# puts schema