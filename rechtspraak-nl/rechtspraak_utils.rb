require 'nokogiri'

require_relative './rechtspraak_search_parser'
include RechtspraakSearchParser

module RechtspraakUtils


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
      # puts "from: #{from}"
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
end