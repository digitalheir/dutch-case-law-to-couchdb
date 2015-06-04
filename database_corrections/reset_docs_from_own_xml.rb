require 'nokogiri'

require_relative '../couch/rechtspraak_expression'
require_relative '../couch/couch'
require_relative '../couch/cloudant_rechtspraak'

per=5
i=0

couch = CloudantRechtspraak.new
couch.each_slice_for_view('ecli', 'query_dev', 'locally_updated?',
                          per,
                          {stale: 'ok',
                           startkey: 'null',
                           endkey: 'null'}) do |rows|
  docs = []
  rows.each do |row|
    ecli = row['id']
    puts ecli
    xml = Nokogiri::XML(open("http://rechtspraak.cloudant.com/ecli/#{ecli}/data.xml"))
    expr = RechtspraakExpression.new(ecli, xml)
    new_doc =expr.doc
    new_doc['_rev'] = row['value']

    docs << new_doc
  end
  couch.flush_bulk('ecli', docs)
  i+=per
  puts i
end
