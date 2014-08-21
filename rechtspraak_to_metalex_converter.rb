class RechtspraakToMetalexConverter
  METALEX_PREFIX = 'metalex'

  def initialize(mapping)
    @mapping = mapping
  end

  def start(root)
    root.add_namespace_definition(METALEX_PREFIX, "http://www.metalex.eu/metalex/1.0")
    root.add_namespace_definition('xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    root['xsi:schemaLocation'] = "http://www.metalex.eu/metalex/1.0 http://justinian.leibnizcenter.org/MetaLex/e.xsd"

    root['id'] = root['id'].gsub('/', ':')

    give_all_elements_id(root, '', {})
    convert_node_names(root)
    # correct_elements()
  end

  def give_all_elements_id(root, path_so_far, ids_already_used, index=nil)
    path_so_far = set_id_for_element(root, ids_already_used, index, path_so_far)

    element_count = {}
    root.element_children.each do |child, i|
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

  def set_id_for_element(root, ids_used, index, path_so_far)
    if root['id']
      puts "NOTE: #{root.name} already had an id: #{root['id']}"
      id=root['id']
    else
      if index
        # TODO use nr if possible
        id="#{path_so_far}:#{root.name}:#{index}"
      else
        id ="#{path_so_far}:#{root.name}"
      end
    end

    duplicate = 1
    while ids_used[id]
      puts "NOTE: #{ids_used[id]} was already in use"
      duplicate += 1
      id = "#{id}:#{duplicate}"
    end

    # Actually set id
    root['id'] = id
    ids_used[id] = true

    id
  end

  def convert_node_names(root)
    if @mapping[root.name]
      element_name = root.name
      root.name = "#{METALEX_PREFIX}:#{@mapping[root.name]}"

      if root['name']
        puts "WARNING: #{element_name} already had a name: #{root['name']}. Overwriting."
      end
      root['name'] = element_name
    else
      raise "#{root.name} was not in mapping."
    end
    root.element_children.each do |child|
      convert_node_names child
    end
  end

end