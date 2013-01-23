unless(node[:repmgr][:repmgr_node_id])
  nodes = discovery_all(
    'repmgr_node_id:*', 
    :raw_search => true,
    :environment_aware => node[:repmgr][:replication][:common_environment],
    :minimum_response_time_sec => false,
    :empty_ok => true
  )

  node.set[:repmgr][:repmgr_node_id] = Array(nodes).map{|r_n|
    r_n[:repmgr][:repmgr_node_id].to_i
  }.max.to_i + 1
end
