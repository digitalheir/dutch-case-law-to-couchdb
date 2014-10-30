require 'json'
require_relative 'couch/couch'

json_paths = Dir['json/*']

new_docs=[]
json_paths.each do |path|
  # puts path
  doc = JSON.parse File.read(path).force_encoding('utf-8')
  doc['_id']=doc['@id']
  doc.delete '@id'
  new_docs << doc
  Couch::CLOUDANT_CONNECTION.flush_bulk_if_big_enough('rechtspraak', new_docs)
end

Couch::CLOUDANT_CONNECTION.flush_bulk_throttled('rechtspraak', new_docs)