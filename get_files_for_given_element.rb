# Script that finds the documents in the ./rich folder that has given element denoted by SEARCH_FOR_ELEMENT

require 'nokogiri'
require 'set'
require 'json'

SEARCH_FOR_ELEMENT = 'alt'
SEARCH_IN_FOLDER = 'rich'

# add element names recursively to given set
def has_element name, root
  if root.name == name
    return true
  else
    root.children.each do |child|
      if has_element name, child
        return true
      end
    end
  end
  false
end

files = Dir["#{SEARCH_IN_FOLDER}/*"]
i=0
files.each do |path|
  xml = Nokogiri::XML File.open(path)
  roots = xml.xpath '/open-rechtspraak/rs:conclusie|/open-rechtspraak/rs:uitspraak', {:rs => 'http://www.rechtspraak.nl/schema/rechtspraak-1.0'}
  if roots.length != 1
    puts "WARNING: Found #{roots.length} roots"
  else
    root = roots.first
    if has_element SEARCH_FOR_ELEMENT, root
      puts path
    end
  end
  # puts path
  i+=1
  if i%1000 == 0
    puts "Handled #{i} files"
  end
  # break
end