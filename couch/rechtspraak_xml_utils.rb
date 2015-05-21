require 'nokogiri'

module RechtspraakXmlUtils

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
end