require_relative 'couch'
require_relative 'secret'
require_relative 'rechtspraak_expression'
include Secret

class CloudantRechtspraak < Couch::Server
  DATABASE_NAME = 'ecli'

  def initialize
    super(
        "#{RECHTSPRAAK_NAME}.cloudant.com", '80',
        {
            name: RECHTSPRAAK_NAME,
            password: RECHTSPRAAK_PASSWORD
        }
    )
  end

  def get_ecli_last_modified(source_docs)
    get_rows_for_view(DATABASE_NAME, 'query', 'ecli_last_modified', {keys: (source_docs.map { |d| [d[:id], "tokens:#{d[:id]}"] }).flatten})
  end

  def update_docs(update_eclis, current_revs=nil, logger=nil)
    i=0
    docs_to_upload = []
    update_eclis.each do |ecli|
      begin
        expr=create_expression(ecli)
        doc = expr.doc

        # Set revision
        set_rev(current_revs, doc)

        docs_to_upload << doc
        flush_bulk_if_big_enough(DATABASE_NAME, docs_to_upload)
        i+=1
        if i%1000==0
          puts "processed #{i} docs"
        end
      rescue => e
        puts "Error processing #{ecli}: #{e.message}"
        if logger
          logger.error "Error processing #{ecli}: #{e.message}"
        end
      end
    end
    flush_bulk_throttled(DATABASE_NAME, docs_to_upload)
  end

  def set_rev(current_revs, doc)
    id = doc['_id']
    rev=nil
    if current_revs and current_revs[id]
      rev = current_revs[id]
    elsif !current_revs
      rev = get_rev(DATABASE_NAME, ecli)
    end
    if rev
      doc['_rev'] = rev
    end
  end

  private
  def create_expression(ecli)
    original_xml = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}"))
    RechtspraakExpression.new(ecli, original_xml)
  end

end