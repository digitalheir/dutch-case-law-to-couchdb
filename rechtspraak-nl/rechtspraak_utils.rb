require 'nokogiri'

require_relative './rechtspraak_expression'
require_relative '../converter/xml_converter'
require_relative './rechtspraak_search_parser'
include RechtspraakSearchParser

module RechtspraakUtils
  DATABASE_NAME = 'ecli'

  # Whether this XML document consists of more than just paragroup, parablock and para elements
  def has_rich_markup root
    # TODO don't need to traverse *entire* tree; finding the first is good enough
    non_para_elements = root.xpath(".//*[local-name()!='para' and local-name()!='parablock' and local-name()!='paragroup']")
    # puts "#{id}: #{all.length}-#{para_block_elements.length}-#{para_elements.length}=#{non_para}"
    non_para_elements.length>0
  end


  # TODO anyway
  # TODO do something about xml:preserve space... a bunch of &nbsp;s?
  # TODO and what about <? breakline ?> ?
  def generate_html(doc)
  end

  def create_couch_doc(ecli)
    # cache_path = "/media/maarten/BA46DFBC46DF7819/Text mining Dutch case law/ecli/#{ecli.gsub(':', '.')}.xml"
    # if File.exists? cache_path
    #   puts "using #{cache_path}"
    #   original_xml = Nokogiri::XML(File.open cache_path)
    # else
    original_xml = Nokogiri::XML(open("http://data.rechtspraak.nl/uitspraken/content?id=#{ecli}"))
    # end
    RechtspraakExpression.new(ecli, original_xml).doc
  end

  def update_docs(update_eclis, current_revs=nil)
    i=0
    docs_to_upload = []
    update_eclis.each do |ecli|
      begin
        doc = create_couch_doc(ecli)

        # Set revision
        rev = nil
        if current_revs and current_revs[ecli]
          rev = current_revs[doc['ecli']]
        elsif !current_revs
          rev = Couch::CLOUDANT_CONNECTION.get_rev(DATABASE_NAME, ecli)
        end
        if rev
          doc['_rev'] = rev
        end

        docs_to_upload << doc
        Couch::CLOUDANT_CONNECTION.flush_bulk_if_big_enough(DATABASE_NAME, docs_to_upload)
        i+=1
        if i%1000==0
          puts "processed #{i} docs"
        end
      rescue
        puts "Error processing #{ecli}"
      end
    end
    Couch::CLOUDANT_CONNECTION.flush_bulk_throttled(DATABASE_NAME, docs_to_upload)
  end

  def get_current_revs(keys=nil)
    revs = {}
    params = {}
    if keys
      params[:keys] = keys
    end
    rows = Couch::CLOUDANT_CONNECTION.get_rows_for_view DATABASE_NAME, 'query', 'rechtspraak_rev', params
    rows.each do |row|
      revs[row['key']] = row['value']
    end
    revs
  end

  # Returns an array of ECLIs that have changed since given date
  def get_new_docs(since='1000-01-01')
    new_docs=[]
    from=0
    params = {
        modified: "[\"#{since}\"]",
        max: 1000,
    }
    loop do
      params[:from] = from
      resp = get_search_response(params)
      from += params[:max]
      puts "from: #{from}"
      if resp[:docs] and resp[:docs].length
        new_docs<<resp[:docs].map { |doc| doc[:id] }
      end
      break unless resp[:docs] and resp[:docs].length>0
    end

    new_docs.flatten
  end

  # Performs given code block for each search result slice in Rechtspraak.nl
  def for_source_docs(since='1000-01-01', &block)
    from=0
    params = {
        modified: "[\"#{since}\"]",
        max: 1000,
    }
    loop do
      params[:from] = from
      resp = get_search_response(params)
      from += params[:max]
      puts "from: #{from}"
      if resp[:docs] and resp[:docs].length
        docs = resp[:docs]
        block.call(docs)
      end
      break unless resp[:docs] and resp[:docs].length>0
    end
  end

  # Checks given ECLIs to our database; call block for those we wish do update
  def evaluate_eclis_to_update(source_docs, &block)
    rows = Couch::CLOUDANT_CONNECTION.get_rows_for_view(DATABASE_NAME, 'query', 'ecli_last_modified', {keys: source_docs.map{|d|d[:id]}})
    our_revs = {}
    rows.each do |row|
      our_revs[row['id']] = {
          :_rev => row['value']['_rev'],
          :modified => row['value']['modified']
      }
    end

    source_docs.each do |doc|
      unless our_revs[doc[:id]] and our_revs[doc[:id]][:modified].gsub(/\+[0-9]{2}:[0-9]{2}$/,'') == doc[:updated].gsub(/\+[0-9]{2}:[0-9]{2}$/,'')
        block.call(doc[:id], our_revs[doc[:id]], doc)
      end
    end
  end
end