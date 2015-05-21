require 'open-uri'
require 'nokogiri'
require 'json'
require 'set'
require_relative '../upload_case_law_to_coucdb/couch'
require_relative 'generate_informal_schema'
# TODO get newly added documents and try to update schema from that
# noinspection RubyStringKeysInHashInspection
existing_mapping = Couch::CLOUDANT_CONNECTION.get_doc('informal_schema', 'informal_schema')
schema_maker = SchemaMaker.new(existing_mapping)

last_update = existing_mapping['generated_on']
puts "Last update done on #{last_update}"
# TODO

files = Dir['../rich/*']
i=0
delete= []
files.each do |path|
  should_be_deleted = schema_maker.find_elements path
  if should_be_deleted
    delete << path
  end
  i+=1
  if i%1000 == 0
    puts "Looked at #{i} files"
    break
  end
  # break
end

delete.each do |p|
  File.delete(p)
end
puts "deleted #{delete.length} invalid files"

schema_maker.elements['generated_on'] = Time.now.strftime('%Y-%m-%d')
Couch::CLOUDANT_CONNECTION.post('/informal_schema/', schema_maker.elements.to_json)
if schema_maker.changes.length > 0
  puts "WARNING: schema has updated with #{schema_maker.changes}"
end

