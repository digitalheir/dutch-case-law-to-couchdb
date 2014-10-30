require 'nokogiri'
require_relative 'converter/xml_converter'

unless File.exist? 'json'
  FileUtils.mkdir_p 'json'
end

@i=0
def create_json(path, is_rich)
  ecli = path.gsub(/^\.\.\//, '').gsub(/^notrich\//, '').gsub(/^rich\//, '').gsub(/\.xml$/, '').gsub('.', ':')
  json_path = "json/#{ecli.gsub(':', '.')}.json"
  unless File.exist? json_path
    xml = Nokogiri::XML(File.read(path))
    conv = XmlConverter.new(ecli, xml)

    doc = conv.get_json_ld
    doc['isRich']=is_rich
    File.open(json_path, 'w+') do |file|
      file.puts doc.to_json
    end
    @i+=1
    if @i % 1000 == 0
      puts "handled #{@i}"
    end
  end
end

rich_docs = Dir['rich/*']
rich_docs.each do |path|
  create_json(path, true)
end

notrich_docs = Dir['notrich/*']
notrich_docs.each do |path|
  create_json(path, false)
end
