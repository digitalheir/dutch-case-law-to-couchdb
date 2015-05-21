require 'open-uri'
require 'nokogiri'
require 'json'
require 'set'
require_relative '../upload_case_law_to_coucdb/couch'
# TODO get newly added documents and try to update schema from that
# noinspection RubyStringKeysInHashInspection
class SchemaMaker
  attr_reader :elements
  attr_reader :changes

  def initialize(elements={})
    @elements = elements
    @changes = []
  end

  def find_elements(path)
    xml = Nokogiri::XML File.open(path)
    roots = xml.xpath '/open-rechtspraak/rs:conclusie|/open-rechtspraak/rs:uitspraak', {:rs => 'http://www.rechtspraak.nl/schema/rechtspraak-1.0'}
    if roots.length != 1
      puts "WARNING: Found #{roots.length} roots in #{path}"
      return true
    else
      root = roots.first
      ecli = path.gsub(/\.\.\/|rich\/|\.xml/, '').gsub('.', ':')
      find_elements_r(root, ecli)
    end
    nil
  end

  private
  def find_elements_r(root, path)
    unless @elements[root.name]
      @elements[root.name] = {
          'attr' => nil,
          'example' => path
      }
      @changes << @elements[root.name]
    end

    find_attributes(path, root)
    find_children(path, root)

    root.element_children.each do |child|
      find_elements_r(child, path)
    end
  end

  def find_children(path, root)
    children = @elements[root.name]['children']
    unless children
      children = {}
    end

    root.element_children.each do |el_child|
      child = children[el_child.name]
      unless child
        children[el_child.name]=path
        @changes << children[el_child.name]
      end
    end

    if children.length > 0
      @elements[root.name]['children'] = children
    end
  end

  def find_attributes(path, root)
    attr_data = @elements[root.name]['attr']
    unless attr_data
      attr_data = {}
      @elements[root.name]['attr']=attr_data
    end

    root.each do |name, val|
      attr = attr_data[name]
      unless attr
        attr = {
            # 'name'=>name,
            'example' => path,
        }
        attr_data[name]=attr
        @changes << attr_data[name]
      end

      if (root.name.match(/uitspraak|conclusie/) and name == 'id') or
          (root.name.match(/imagedata/) and name == 'width') or
          (root.name.match(/imagedata/) and name == 'depth') or
          (root.name.match(/footnote-ref/) and name == 'linkend') or
          (root.name.match(/footnote/) and name == 'id') or
          (root.name.match(/imagedata/) and name == 'fileref')
        # Don't list all the eclis we find
        # attr['values'] = nil
      else
        # Just make a hash of values encountered
        if root.name.match(/footnote/) and name == 'label' and val.match(/[0-9]+/)
          val = '/[0-9]+/'
          value = ''
        else
          value = attr['values'][val]
        end
        unless attr['values']
          attr['values'] = {}
        end
        unless value
          value = path
          attr['values'][val] = value
          @changes << attr['values'][val]
        end
      end
    end
  end
end

# noinspection RubyStringKeysInHashInspection
existing_mapping = Couch::CLOUDANT_CONNECTION.get_doc('informal_schema', 'informal_schema')
if !existing_mapping and File.exist? 'informal_schema.json'
  existing_mapping = JSON.parse(File.read('informal_schema.json'))
  existing_mapping['_id'] = 'informal_schema'
end
schema_maker = SchemaMaker.new(existing_mapping)


# TODO
files = Dir['../rich/*']
i=0
delete= []
files.each do |path|
  should_be_deleted = schema_maker.find_elements path
  if should_be_deleted
    delete << path
  end
  i+=1
  if i%1000 == 0
    puts "Looked at #{i} files"
    break
  end
  # break
end

delete.each do |p|
  File.delete(p)
end
puts "deleted #{delete.length} invalid files"

if schema_maker.changes.length > 0
  schema_maker.elements['generated_on'] = Time.now.strftime('%Y-%m-%d')
  File.open('informal_schema.json', 'w+') do |f|
    f.puts JSON.pretty_generate(schema_maker.elements)
  end
  Couch::CLOUDANT_CONNECTION.post('/informal_schema/', schema_maker.elements.to_json)
  puts "WARNING: schema has updated with #{schema_maker.changes}"
end

