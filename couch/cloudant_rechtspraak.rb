require_relative 'couch'
require_relative 'secret'
require_relative 'rechtspraak_expression'
require_relative 'rechtspraak_expression_tokenized'
include Secret

class CloudantRechtspraak < Couch::Server
  def initialize(db='ecli')
    super(
        "#{RECHTSPRAAK_NAME}.cloudant.com", '80',
        {
            name: RECHTSPRAAK_NAME,
            password: RECHTSPRAAK_PASSWORD
        }
    )
    @cache = []
    @db=db
  end

  def get_ecli_last_modified(source_docs)
    get_rows_for_view(@db, 'query', 'ecli_last_modified', {keys: (source_docs.map { |d| [d[:id], "tokens:#{d[:id]}"] }).flatten})
  end

  def for_docs_since(year, month, day, &block)
    each_slice_for_view(@db, 'query_dev', 'locally_updated', 150, {
                               startkey: [year, month, day]
                           })
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
        flush_bulk_if_big_enough(@db, docs_to_upload)
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
    flush_bulk_throttled(@db, docs_to_upload)
  end

  def set_rev(current_revs, doc)
    id = doc['_id']
    rev=nil
    if current_revs and current_revs[id]
      rev = current_revs[id]
    elsif !current_revs
      rev = get_rev(@db, id)
    end
    if rev
      doc['_rev'] = rev
    end
  end

  def add_and_maybe_flush(new_doc)
    @cache << new_doc
    flush_bulk_if_big_enough(@db, @cache)
  end

  def flush
    flush_bulk_throttled(@db, @cache)
    @cache.clear
  end

  def get_current_revs
    map = {}
    (get_rows_for_view @db, 'query', 'rechtspraak_rev', {}).each do |el|
      map[el['key']]=el['value']
    end
    map
  end

  private
  def create_expression(ecli)
    original_xml = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}"))
    RechtspraakExpression.new(ecli, original_xml)
  end

end