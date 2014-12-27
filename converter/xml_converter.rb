require 'json'
require 'tilt'
require 'erb'
require_relative 'metadata_handler_graph'
require_relative 'metadata_handler_jsonld'
require_relative 'metadata_handler_metalex'

METALEX_PREFIX = 'metalex'

# XSD = Nokogiri::XML::Schema(open('converter/e.xsd').read)
TO_HTML = Nokogiri::XSLT(File.open('converter/xslt/rechtspraak_to_html.xslt'))
EXTRACT_TOC = Nokogiri::XSLT(File.open('converter/xslt/rechtspraak_extract_toc.xslt'))
HTML_SHOW_TEMPLATE = Tilt.new('converter/erb/show.html.erb', :default_encoding => 'utf-8')
MAPPING = JSON.parse(File.read('converter/rechtspraak_mapping.json'))

class XmlConverter
  JSON_LD_URI = 'http://assets.lawly.eu/ld/context.jsonld'

  attr_reader :original
  attr_reader :metalex
  attr_reader :html_show
  attr_reader :html_inner
  attr_reader :html_toc

  def initialize(ecli, xml)
    @ecli=ecli
    @mapping=MAPPING
    @original = xml
  end

  def get_rdf_metadata
    MetadataHandler.new xml, ecli
  end

  # Creates inner HTML, TOC, and the Lawly page that binds all data together
  def generate_html(from_doc)
    # TODO do something about xml:preserve space... a bunch of &nbsp;s?
    # TODO and what about <? breakline ?> ?
    @html_inner = TO_HTML.transform(@metalex).to_s
    @html_toc = EXTRACT_TOC.transform(@metalex).to_s

    @html_show = HTML_SHOW_TEMPLATE.render(Object.new, {
        :page_title => from_doc['dcterms:title'],
        :date_last_modified => from_doc['dcterms:modified'],
        :description => from_doc['dcterms:abstract'],
        :inner_html => @html_inner,
        :toc => @html_toc
    })
  end

  def convert_to_metalex
    @metalex = Nokogiri::XML(@original.to_s)
    @metalex.root.add_namespace_definition(METALEX_PREFIX, 'http://www.metalex.eu/metalex/1.0')
    @metalex.root.add_namespace_definition('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    @metalex.root['xsi:schemaLocation'] = 'http://www.metalex.eu/metalex/1.0 http://justinian.leibnizcenter.org/MetaLex/e.xsd'

    stripper = MetadataStripper.new @metalex, @ecli
    metadata_element = stripper.strip_metadata

    give_all_elements_id(@metalex.root, '', {})
    convert_node_names(@metalex.root)
    add_metadata_container(@metalex, metadata_element)

    @metalex
  end

  def get_json_ld
    metadata_handler = MetadataHandlerJsonLd.new(@original, @ecli)
    metadata_handler.metadata
  end

  private

  def add_metadata_container(xml, node)
    if xml.children.length > 0
      xml.root.children.first.add_previous_sibling(node)
    else
      xml << node
    end
  end

  # Recursively gives elements an identifier.
  # Id is based on the tag name, number by occurrence (single occurrences on a certain depth are not numbered).
  def give_all_elements_id(root, path_so_far, ids_already_used, index=nil)
    path_so_far = set_id_for_element(root, ids_already_used, index, path_so_far)

    # First count all elements
    element_count = {}
    root.element_children.each do |child, _|
      this_kind_of_child_count = element_count[child.name] || 0
      this_kind_of_child_count += 1
      element_count[child.name] = this_kind_of_child_count
    end

    running_count = {}
    root.element_children.each do |child|
      if element_count[child.name] < 2
        child_index = nil
      else
        child_index = running_count[child.name] || 0
        child_index += 1
        running_count[child.name] = child_index
      end
      give_all_elements_id(child, path_so_far, ids_already_used, child_index)
    end
  end

  # Sets an id attribute for every element
  # NOTE: I use colons instead of slashes, because a string with slashes does not count as NMTOKEN when validating against metalex schema
  def set_id_for_element(root, ids_used, index, path_so_far)
    if root['id']
      unless root.name == 'uitspraak' or root.name == 'conclusie' or root.name == 'footnote'
        puts "NOTE: #{root.name} already had an id: #{root['id']}"
      end
      id=root['id']
    else
      element_name = root.name.gsub(' ', '_')
      if index
        # TODO use nr if possible
        id="#{path_so_far}:#{element_name}:#{index.to_s.gsub(/[ \/\*]/, '_')}"
      else
        id ="#{path_so_far}:#{element_name}"
      end
    end

    # Check if id is already used
    if ids_used[id]
      puts "NOTE: #{ids_used[id]} was already in use"
      duplicate_nr = 1
      temp_id = "#{id}:#{duplicate_nr}"
      while ids_used[temp_id]
        puts "NOTE: #{temp_id} was also in use"
        duplicate_nr += 1
        temp_id = "#{id}:#{duplicate_nr}"
      end
      id = temp_id
    end

    # Actually set id to element
    root['id'] = id
    ids_used[id] = true

    id
  end

  # Converts Rechtspraak.nl nodes to the corresponding Metalex nodes as defined in the mapping
  def convert_node_names(root)
    element_name = root.name
    root.namespace = nil
    if @mapping[root.name]
      root.name = "#{METALEX_PREFIX}:#{@mapping[root.name]}"
    else
      puts "WARNING: #{root.name} was not in mapping."
      root.name = "#{METALEX_PREFIX}:inline"
    end

    if root['name']
      puts "WARNING: #{element_name} already had a name: #{root['name']}. Overwriting."
    end
    root['name'] = element_name
    root.element_children.each do |child|
      convert_node_names child
    end
  end

  # Matches, for instance 'U I t S pR  a A k something following'
  RE_UITSPRAAK = /\s*[Uu]\s{0,2}[Ii]\s{0,2}[Tt]\s{0,2}[Ss]\s{0,2}[Pp]\s{0,2}[Rr]\s{0,2}[Aa]\s{0,2}[Aa]\s{0,2}[KK][^<]*/

# def improve_xml(root_soup, ecli)
#   doc_root = root_soup.contents[0]
#
#   # Convert 'uitspraak' or 'conclusie' to 'doc' with @role=rechtspraak:uitspraak|rechtspraak:conclusie
#   doc_root['role'] = "http://psi.rechtspraak.nl/" + doc_root.name.lower()
#   doc_root['id'] = ecli
#   doc_root.name = 'doc'
#
#   # para elements
#   all_elements = doc_root.find_all()
#   para_elements = doc_root.find_all(RE_PARA)
#   if len(para_elements) == len(all_elements)
#     #logging.debug("Processing a para doc")
#     # Wrap <para>'UITSPRAAK'</para> and following nodes in a <judgment> tag
#     tags = doc_root.find_all(name='para', text=RE_UITSPRAAK)
#     for tag in tags
#       tag.name = 'header'
#       #     wrapper = root_soup.new_tag("judgment")
#       #     while not (tag.next_sibling is None or tag.next_sibling in tags):
#       #         wrapper.append(tag.next_sibling)
#       #     tag.insert_after(wrapper)
#       #     wrapper.insert(0, tag)
#       else
#       logging.warning("Processing a richer doc: " + ecli)
#     end
#     # Return enriched xml
#     return doc_root
#   end
# end
  RE_PARA = /^para(group|block)?$/
end