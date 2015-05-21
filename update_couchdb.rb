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


def update_couchdb
  today = Date.today.strftime('%Y-%m-%d')
  doc_last_updated = Couch::CLOUDANT_CONNECTION.get_doc('informal_schema', 'general')

  for_source_docs() do |docs|
    # Get docs to update
    update_docs = {}
    docs.each_slice(200) do |subgroup|
      evaluate_eclis_to_update(subgroup) do |id, our_data, source_data|
        if our_data
          update_docs[id] = our_data
        else
          update_docs[id] = {
              _rev: nil,
              modified: source_data[:updated]
          }
        end
      end
    end
    puts "#{update_docs.length} new docs"

    # Update docs
    if update_docs.length > 0
      revs = {}
      new_docs = []
      update_docs.each do |ecli, data|
        if data[:_rev]
          revs[ecli] = data[:_rev]
        end
        new_docs << ecli
      end

      update_docs(new_docs, revs)
    end
  end

  # Update the document that tracks our last update date
  doc_last_updated['date_last_updated'] = today
  Couch::CLOUDANT_CONNECTION.put('/informal_schema/general', doc_last_updated.to_json)
end

# Script starts here

RES_MAX=1000
LOGGER = Logger.new('update_couchdb.log')
update_couchdb
LOGGER.close