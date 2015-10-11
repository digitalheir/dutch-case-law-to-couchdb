require_relative '../couch/cloudant_rechtspraak'

@c=CloudantRechtspraak.new
i=0
def delete_condition(doc)
  doc['_attachments'] and doc['_attachments']['data.htm'] and doc['_attachments']['data.htm']['length'] < 6
end

@c.all_docs('ecli',50_000,{include_docs:true}) do |docs|
  docs.each do |row|
    doc = row['doc']
    if delete_condition(doc)
      puts "Adding #{doc['_id']}"
      doc['_deleted']=true
      @c.add_and_maybe_flush doc
    end
  end
  i+=docs.length
  puts i
end
@c.flush

