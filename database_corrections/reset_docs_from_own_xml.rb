require 'nokogiri'

require_relative '../couch/rechtspraak_expression'
require_relative '../../couch/couch'

per=250
i=0

class Cloudant < Couch::Server
  def initialize
    super(
        'rechtspraak.cloudant.com', '80',
        {
            name: 'rechtspraak',
            password: 'ssssssssecret'
        }
    )
  end
end

couch = Cloudant.new
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
    new_doc = RechtspraakExpression.new(ecli, xml).doc
    new_doc['_rev'] = row['value']

    docs<<new_doc
  end
  couch.flush_bulk('ecli', docs)
  i+=per
  puts i
end
