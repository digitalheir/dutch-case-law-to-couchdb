require_relative '../couch/couch'


all_docs = Couch::CLOUDANT_CONNECTION.get_all_docs('rechtspraak', {:include_docs => true, 'limit'=>10000})
 puts "Found #{all_docs.length}"
bulk = []
max=750
all_docs.each do |doc|
  if doc['_id'].start_with? 'ECLI:'
    bulk<<doc
    doc['_deleted']=true
    if bulk.length >= max
      Couch::CLOUDANT_CONNECTION.flush_bulk('rechtspraak', bulk)
      bulk.clear
      puts "flushed #{max}"
    end
  end
end
if bulk.length >= 0
  Couch::CLOUDANT_CONNECTION.flush_bulk('rechtspraak', bulk)
end
