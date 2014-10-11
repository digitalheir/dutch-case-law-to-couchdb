require 'json'
require 'base64'
     require_relative '../couch/couch'
doc = JSON.parse('{
  "_id": "ld"
}')

puts Dir.getwd
doc['_attachments'] ||= {}
doc['_attachments']['context.jsonld'] = {
    'content_type' => 'application/ld+json',
    'data' => Base64.encode64(File.read('context.jsonld'))
}

Couch::LAW.put('/assets/ld',doc.to_json)