require 'open-uri'
require 'nokogiri'

from=300000 # start from 300000 because most old docs aren't rich
feed = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/zoeken?return=DOC&max=1000&from=#{from}"))
feed.remove_namespaces!
id_nodes = feed.xpath('/feed/entry/id')

subtitle_node = feed.xpath('/feed/subtitle')
total = subtitle_node.text
while id_nodes.length > 0 do
  id_nodes.each do |id_node|
    id = id_node.text
    #/ECLI:[A-Za-z]*:([^:]*):[^:]*:[^:]*/ =~ id
    filename = "#{id}.xml"
    filename.gsub! ':', '.'

    unless File.exists? "rich/#{filename}" or File.exists? "notrich/#{filename}"
      # puts id.text
      doc_url = "http://data.rechtspraak.nl/uitspraken/content?id=#{id_node.text}"
      doc = Nokogiri::XML(open(doc_url))

      root = doc.xpath '/open-rechtspraak/rs:conclusie|/open-rechtspraak/rs:uitspraak', {:rs => 'http://www.rechtspraak.nl/schema/rechtspraak-1.0'}
      if root.length != 1
          puts "ERROR: number conclusie/uitspraak elements in #{id} was not 1"
      else
        # TODO don't need to traverse *entire* tree; finding the first is good enough
        non_para_elements = root.xpath(".//*[local-name()!='para' and local-name()!='parablock' and local-name()!='paragroup']")
        # puts "#{id}: #{all.length}-#{para_block_elements.length}-#{para_elements.length}=#{non_para}"
        if non_para_elements.length>0
          path = "rich/#{filename}"
          puts "#{id} had #{non_para_elements.length} non-para items"
          FileUtils.mkdir_p File.dirname(path) unless File.exists? File.dirname(path)
          File.open(path, 'w') do |file|
            file.write(doc.to_s)
          end
        else
          #puts "#{id} had only para items"
          path = "notrich/#{filename}"
          FileUtils.mkdir_p File.dirname(path) unless File.exists? File.dirname(path)
          File.open(path, 'w') do |file|
            file.write(doc.to_s)
          end
        end
      end
    # else
      # puts "Already downloaded #{path}"
    end
  end
  from += 1000
  puts "#{from} / #{total}"
  feed = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/zoeken?return=DOC&max=1000&from=#{from}"))
  feed.remove_namespaces!
  id_nodes = feed.xpath('/feed/entry/id')
end