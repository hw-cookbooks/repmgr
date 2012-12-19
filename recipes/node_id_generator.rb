# TODO: You know what would be nice? Using zookeeper for this.

set_repmgr_id = lambda do
  cur_max = search(:node, 'repmgr_node_id:*').map{|rnode|
    rnode[:repmgr][:repmgr_node_id].to_i
  }.max.to_i

  new_id = cur_max + 1

  node.set[:repmgr][:repmgr_node_id] = new_id
  node.save
  new_id
end

wanted_id = set_repmgr_id.call
found = false
until(found) do
  reset_id = false
  Chef::Log.info "Searching for matching node with repmgr ID of #{wanted_id}"
  rnodes = search(:node, "repmgr_node_id:#{wanted_id}")
  if(rnodes.size == 1 && rnodes.first.name == node.name)
    Chef::Log.info "Found me and only me with repmgr ID of #{wanted_id}. Yay \\o/"
    found = true
  else
    if(rnodes.size > 1)
      Chef::Log.warn "Found multiple nodes with ID #{wanted_id}. Trying new ID (#{rnodes.inspect})"
      reset_id = true
    else
      Chef::Log.warn "No nodes found with repmgr ID #{wanted_id}. Searching again..."
    end
  end
  unless(found)
    sleep(rand(node[:repmgr][:id_generator_splay]))
    wanted_id = set_repmgr_id.call if reset_id
  end
end


