require 'couch'
require 'net/http'
require 'uri'
require_relative 'rechtspraak_expression'
require_relative 'rechtspraak_expression_tokenized'

class CloudantRechtspraak < Couch::Server
  def initialize(db='ecli')
    super(
        ENV['RECHTSPRAAK_URL'],
        {
            name: ENV['RECHTSPRAAK_NAME'],
            password: ENV['RECHTSPRAAK_PASSWORD'],
        }
    )
    @cache = []
    @db=db
  end

  def get_ecli_last_modified(source_docs)
    get_rows_for_view(@db, 'query', 'ecli_last_modified', {keys: (source_docs.map { |d| [d[:id], "tokens:#{d[:id]}"] }).flatten})
  end

  def update_docs(update_eclis, current_revs=nil)
    i=0
    docs_to_upload = []
    update_eclis.each do |ecli|
      begin
        expr=create_expression(ecli)
        doc = expr.doc

        # Set revision
        set_rev(current_revs, doc)

        docs_to_upload << doc
        post_bulk_if_big_enough(@db, docs_to_upload)
        i+=1
        if i%1000==0
          puts "processed #{i} docs"
        end
      rescue => e
        $stderr.puts "Error processing #{ecli}: #{e.message}"
      end
    end
    post_bulk_throttled(@db, docs_to_upload)
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
    post_bulk_if_big_enough(@db, @cache)
  end

  def flush
    post_bulk_throttled(@db, @cache)
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
    original_xml = get_official_xml(ecli)
    RechtspraakExpression.new(ecli, original_xml)
  end

  def get_official_xml(ecli)
    url = URI.parse "http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}"
    req = Net::HTTP::Get.new(url)
    res = Net::HTTP.start(url.host, url.port,
                          :use_ssl => url.scheme =='https') do |http|
      http.open_timeout = 30*60
      http.read_timeout = 30*60
      http.request(req)
    end
    if res.kind_of?(Net::HTTPSuccess)
      Nokogiri::XML(res.body)
    else
      raise RuntimeError.new("#{res.code}:#{res.message}\nMETHOD:#{req.method}\nURI:#{req.path}\n#{res.body}")
    end
  end

end