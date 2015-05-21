require 'nokogiri'
require 'json'
require 'erb'
require 'logger'
require 'tilt'
require 'open-uri'
require 'base64'
require_relative 'couch/couch'
require_relative 'rechtspraak-nl/rechtspraak_utils'
include RechtspraakUtils

# Deprecated for being inefficient on memory

def update_couchdb
  today = Date.today.strftime('%Y-%m-%d')
  doc_last_updated = Couch::CLOUDANT_CONNECTION.get_doc('informal_schema', 'general')

  # Resolve new docs and update database
  current_revs = get_current_revs
  puts "found #{current_revs.length} documents in db"

  new_docs = get_new_docs(doc_last_updated['date_last_updated'])
#todo REMOVE
new_docs
new_docs.select! {|ecli| current_revs[ecli].nil?}
#TODO remove
  puts "#{new_docs.length} new docs"

  update_docs(new_docs,current_revs)

  # Update the document that tracks our last update date
  doc_last_updated['date_last_updated'] = today
  Couch::CLOUDANT_CONNECTION.put('/informal_schema/general', doc_last_updated.to_json)
end

# Script starts here

RES_MAX=1000
LOGGER = Logger.new('update_couchdb.log')
update_couchdb
LOGGER.close