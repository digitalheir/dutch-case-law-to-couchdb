###################
####            ###
#### DEPRECATED ###
####            ###
###################
# require 'nokogiri'
# require_relative 'converter/xml_converter'
# require_relative 'couch/couch'
#
# unless File.exist? 'json'
#   FileUtils.mkdir_p 'json'
# end
#
# @i=0
# @docs = []
#
# def create_json(path, is_rich)
#   ecli = path.gsub(/^\.\.\//, '').gsub(/^notrich\//, '').gsub(/^rich\//, '').gsub(/\.xml$/, '').gsub('.', ':')
#   if @has_id[ecli]
#     File.delete(path)
#   else
#     json_path = "json/#{ecli.gsub(':', '.')}.json"
#     begin
#       unless File.exist? json_path
#         xml = Nokogiri::XML(File.read(path).force_encoding('utf-8'))
#         conv = XmlConverter.new(ecli, xml)
#
#         doc = conv.get_json_ld
#         doc['isRich']=is_rich
#         @docs << doc
#
#         Couch::CLOUDANT_CONNECTION.flush_bulk_if_big_enough('rechtspraak', @docs)
#
#         @i+=1
#         if @i % 1000 == 0
#           puts "handled #{@i}"
#         end
#       end
#     rescue
#       puts "Problem with #{ecli}"
#     end
#   end
# end
#
# all_ids = Couch::CLOUDANT_CONNECTION.get_all_ids('rechtspraak', {:startkey => '"ECLI"', :endkey => '"FCLI"'})
# @has_id = {}
# all_ids.each do |id|
#   @has_id[id] =true
# end
# puts "already have #{@has_id.length} ids"
# rich_docs = Dir['rich/*']
# rich_docs.each do |path|
#   create_json(path, true)
# end
#
# notrich_docs = Dir['notrich/*']
# notrich_docs.each do |path|
#   create_json(path, false)
# end
# if @docs.length>0
#   Couch::CLOUDANT_CONNECTION.flush_bulk_throttled('rechtspraak', @docs)
# end
