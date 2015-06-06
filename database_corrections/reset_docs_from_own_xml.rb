require 'nokogiri'

require_relative '../couch/rechtspraak_expression'
require_relative '../couch/couch'
require_relative '../couch/cloudant_rechtspraak'

per=200
i=0

couch = CloudantRechtspraak.new
couch.each_slice_for_view('ecli',
                          'query_dev', 'locally_updated',
                          per,
                          {
                              # stale: 'ok',
                              # startkey: 'null',
                              # endkey: '[2015,6,5]',
                              limit: 100
                          }) do |rows|
  docs = []
  rows.each do |row|
    ecli = row['id']
    xml = Nokogiri::XML(open("http://rechtspraak.cloudant.com/ecli/#{ecli}/data.xml"))
    expr = RechtspraakExpression.new(ecli, xml)
    new_doc =expr.doc
    new_doc['_rev'] = row['value']

    if new_doc['dcterms:references']
      # puts ecli
    end
    if new_doc['dcterms:relation']
      puts ecli
    end
    docs << new_doc
  end
  couch.flush_bulk('ecli', docs)
  i+=per
  puts i
end
