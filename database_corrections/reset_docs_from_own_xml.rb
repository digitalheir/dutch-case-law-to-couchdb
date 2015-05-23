require 'nokogiri'

require_relative '../rechtspraak-nl/rechtspraak_expression'
require_relative '../converter/xml_converter'
require_relative '../couch/couch'

per=100
i=0

Couch::CLOUDANT_CONNECTION.each_slice_for_view('ecli', 'query_dev', 'locallyUpdated?',
                                               per,
                                               {stale: 'ok',
                                                startkey: 'null',
                                                limit: 15000,
                                                endkey: 'null'}) do |rows|
  docs = []
  rows.each do |row|
    ecli = row['id']
    puts ecli
    xml = Nokogiri::XML(open("http://rechtspraak.cloudant.com/ecli/#{ecli}/data.xml"))
    new_doc = RechtspraakExpression.new(ecli, xml).doc
    new_doc['_rev'] = row['value']

    docs<<new_doc
  end
  Couch::CLOUDANT_CONNECTION.flush_bulk('ecli', docs)
  i+=per
  puts i
end