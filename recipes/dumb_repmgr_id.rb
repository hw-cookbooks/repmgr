unless(node[:repmgr][:config][:node])
  nodes = discovery_all(
    'repmgr_config_node:*', 
    :raw_search => true,
    :environment_aware => node[:repmgr][:replication][:common_environment],
    :minimum_response_time => false,
    :empty_ok => true
  )

  node.set[:repmgr][:config][:node] = Array(nodes).map{|r_n|
    r_n[:repmgr][:config][:node].to_i
  }.max.to_i + 1
end
