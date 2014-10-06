require 'nokogiri'
require 'json'
require 'erb'
require 'logger'
require 'tilt'
require 'open-uri'
require 'base64'
require_relative 'couch/couch'
require_relative 'couch/rechtspraak_expression'
require_relative 'couch/rechtspraak_work'
require_relative 'converter/xml_converter'

RES_MAX=1000

LOGGER = Logger.new('update_couchdb.log')

def add_expression_and_work(new_docs, path, rich_markup)
  ecli = path.gsub(/^\.\.\//, '').gsub(/^rich\//, '').gsub(/\.xml$/, '').gsub('.', ':')
  original_xml = Nokogiri::XML(File.read(path))

  expression = RechtspraakExpression.new(ecli, original_xml, rich_markup)
  # new_docs << expression.doc

  work = RechtspraakWork.new(ecli,expression.doc)
  work.set_show_html(expression.doc['_attachments']['show.html'])

  new_docs << work.doc
end

def initialize_couchdb
  i=0
  new_docs = []
  rich_docs = Dir['rich/*']
  rich_docs.each do |path|
    rich_markup=true
    add_expression_and_work(new_docs, path, rich_markup)
    Couch::CLOUDANT_CONNECTION.flush_bulk_if_big_enough('rechtspraak', new_docs)
    i+=1
    if i%1000==0
      puts "processed #{i} docs"
    end
  end

  not_rich_docs = Dir['notrich/*']
  not_rich_docs.each do |path|
    rich_markup=false
    add_expression_and_work(new_docs, path, rich_markup)
    Couch::CLOUDANT_CONNECTION.flush_bulk_if_big_enough('rechtspraak', new_docs)
    i+=1
    if i%1000==0
      puts "processed #{i} docs"
    end
  end

  Couch::CLOUDANT_CONNECTION.flush_bulk_throttled('rechtspraak', new_docs)
end

def update_couchdb

end

initialize_couchdb
# update_couchdb
LOGGER.close

#
# new_expressions = {}
# from = 0
# loop do
#   uri = URI.parse('http://dutch-case-law.herokuapp.com/search')
#   uri.query = URI.encode_www_form({
#                                       max: RES_MAX,
#                                       from: from,
#                                       # modified: ["2014-09-25"]
#                                   })
#   puts "Opening #{uri.to_s}"
#   data = JSON.parse open(uri).read
#   if data and data['docs'].length > 0
#     data['docs'].each do |doc|
#       new_expressions[doc['id']]=doc
#     end
#   else
#     break
#   end
#
#   if new_expressions.length >= 1000 #TODO
#     break
#   end
#   from += RES_MAX
# end
#
# update_keys = []
# new_expressions.each do |ecli, _|
#   update_keys << ecli
#   if update_keys.length >= 10
#     process_eclis update_keys, new_expressions
#     puts "Processed #{update_keys.length} keys"
#     update_keys.clear
#
#     break #TODO
#   end
# end
#
