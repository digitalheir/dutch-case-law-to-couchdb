#Script to download all documents with the folder structure determined by their ecli, eg ECLI:NL:CRVB:1999:AA4177 becomes ./ECLI/NL/CRVB/1999/AA4177.xml

require 'open-uri'
require 'nokogiri'

from=0
feed = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/zoeken?return=DOC&max=1000&from=#{from}"))
feed.remove_namespaces!
id_nodes = feed.xpath('/feed/entry/id')

subtitle_node = feed.xpath('/feed/subtitle')
total = subtitle_node.text
while id_nodes.length > 0 do
  id_nodes.each do |id_node|
    id = id_node.text
    #/ECLI:[A-Za-z]*:([^:]*):[^:]*:[^:]*/ =~ id
    path = "#{id}.xml"
    path.gsub! /:/, '/'
    unless File.exists? path
      # puts id.text
      doc_url = "http://data.rechtspraak.nl/uitspraken/content?id=#{id_node.text}"
      doc = Nokogiri::XML(open(doc_url))

      root = doc.xpath '/open-rechtspraak/rs:conclusie|/open-rechtspraak/rs:uitspraak', {:rs => 'http://www.rechtspraak.nl/schema/rechtspraak-1.0'}
      if root.length != 1
          puts "ERROR: number conclusie/uitspraak elements in #{id} was not 1"
      else
        non_para_elements = root.xpath(".//*[local-name()!='para' and local-name()!='parablock' and local-name()!='paragroup']")
        # puts "#{id}: #{all.length}-#{para_block_elements.length}-#{para_elements.length}=#{non_para}"
        if non_para_elements.length>0
          puts "#{id} had #{non_para_elements.length} non-para items"
        else
          # puts "#{id} had only para items"
          FileUtils.mkdir_p File.dirname(path) unless File.exists? File.dirname(path)
          File.open(path, 'w') do |file|
            file.write(doc.to_s)
          end
        end
      end
    end
  end
  from += 1000
  puts "#{from} / #{total}"
  feed = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/zoeken?return=DOC&max=1000&from=#{from}"))
  feed.remove_namespaces!
  id_nodes = feed.xpath('/feed/entry/id')
end