require 'json'
require 'base64'
require_relative '../couch/couch'

puts Dir.getwd


doc = JSON.parse(Couch::WETTEN_CONNECTION.get('/assets/ld').body)
# noinspection RubyStringKeysInHashInspection
doc['_attachments']['rechtspraak_context.jsonld'] = {
    'content_type' => 'application/ld+json',
    'data' => Base64.encode64(File.read('rechtspraak_context.jsonld'))
}

Couch::WETTEN_CONNECTION.flush_bulk('assets', [doc])