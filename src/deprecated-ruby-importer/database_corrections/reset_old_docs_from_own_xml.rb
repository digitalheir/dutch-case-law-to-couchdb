require 'nokogiri'
require 'json'

require_relative '../couch/rechtspraak_expression'
require_relative '../couch/cloudant_rechtspraak'

per=50
i=0

DB_NAME = 'ecli'

BEFORE=[2015, 9, 25]
BEFORE_STR='2015-09-20'

couch = CloudantRechtspraak.new
couch.rows_for_view(
    DB_NAME,
    'query_dev', 'locally_updated',
    500,
    {
        stale: 'ok',
        # startkey: 'null',
        endkey: BEFORE.to_json,
        # limit: 100
    }) do |rows|
  new_doc=nil
  rows.each do |row|
    ecli = row['id']
    xml = Nokogiri::XML(open("http://rechtspraak.cloudant.com/#{DB_NAME}/#{ecli}/data.xml"))
    expr = RechtspraakExpression.new(ecli, xml)
    new_doc = expr.doc
    unless row['value']
      raise "Uhh #{row['value']}"
    end

    new_doc['_rev'] = row['value']

    # if new_doc['dcterms:references']
    # puts ecli
    # end
    # if new_doc['dcterms:relation']
    #   puts ecli
    # end
    has_flushed = couch.add_and_maybe_flush(new_doc)
    i+=1
    # puts "#{i}"
    if has_flushed
      puts "#{i} - #{new_doc['ecli']}"
    end
  end
end
