require 'nokogiri'
require 'json'
require 'erb'
require 'logger'
require 'tilt'
require 'open-uri'
require 'base64'
require_relative 'couch/couch'
require_relative 'couch/rechtspraak_expression'
require_relative 'converter/xml_converter'
require_relative 'rechtspraak_search_parser'
include RechtspraakSearchParser

def create_couch_doc(ecli)
  # cache_path = "/media/maarten/BA46DFBC46DF7819/Text mining Dutch case law/ecli/#{ecli.gsub(':', '.')}.xml"
  # if File.exists? cache_path
  #   puts "using #{cache_path}"
  #   original_xml = Nokogiri::XML(File.open cache_path)
  # else
    original_xml = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}"))
  # end
  RechtspraakExpression.new(ecli, original_xml).doc
end

def update_docs current_revs, update_eclis
  i=0
  docs_to_upload = []
  update_eclis.each do |ecli|
   begin
    doc = create_couch_doc(ecli)
    if current_revs[ecli]
      doc['_rev'] = current_revs[doc['ecli']]
    end

    docs_to_upload << doc
    Couch::CLOUDANT_CONNECTION.flush_bulk_if_big_enough(DATABASE_NAME, docs_to_upload)
    i+=1
    if i%1000==0
      puts "processed #{i} docs"
    end
   rescue
    puts "Error processing #{ecli}"
   end
  end
  Couch::CLOUDANT_CONNECTION.flush_bulk_throttled(DATABASE_NAME, docs_to_upload)
end

# Returns an array of ECLIs that have changed since given date
def get_new_docs(since)
  since = "1888-05-13"
  new_docs=[]
  from=0
  params = {
      modified: "[\"#{since}\"]",
      max: 1000
  }
  loop do
    params[:from] = from
    resp = get_search_response(params)
    from += params[:max]
    puts "from: #{from}"
    if resp[:docs] and resp[:docs].length
      new_docs<<resp[:docs].map { |doc| doc[:id] }
    end
    break unless resp[:docs] and resp[:docs].length>0
  end

  new_docs.flatten
end

def get_current_revs
  revs = {}
  rows = Couch::CLOUDANT_CONNECTION.get_rows_for_view 'ecli', 'query', 'rechtspraak_rev'#, {'stale'=>'ok'}
  rows.each do |row|
    revs[row['key']] = row['value']
  end
  revs
end

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

  update_docs(current_revs, new_docs)

  # Update the document that tracks our last update date
  doc_last_updated['date_last_updated'] = today
  Couch::CLOUDANT_CONNECTION.put('/informal_schema/general', doc_last_updated.to_json)
end

# Script starts here

RES_MAX=1000
DATABASE_NAME = 'ecli'

LOGGER = Logger.new('update_couchdb.log')

update_couchdb
LOGGER.close