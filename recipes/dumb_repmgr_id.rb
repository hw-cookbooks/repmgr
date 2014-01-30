# race conditions can occur whereby nodes get conflicting
# id numbers and repmgr registration will fail
# * multiple nodes are started at the same time
#   - both get the same starting number
# * a node is added after a node has been deleted
#   - it will get a number that has already been used
# previous code relies on node attributes not being
# saved until end of run but other recipes can do this

unless(node[:repmgr][:node_status_confirmed])
  unless(node[:repmgr][:config][:node])
    nodes = discovery_all(
      'repmgr_config_node:*', 
      :raw_search => true,
      :environment_aware => node[:repmgr][:replication][:common_environment],
      :minimum_response_time_sec => false,
      :empty_ok => true
    )

    node.set[:repmgr][:config][:node] = Array(nodes).map{|r_n|
      r_n[:repmgr][:config][:node].to_i
    }.max.to_i + 1
  else
    node.set[:repmgr][:config][:node] = node[:repmgr][:config][:node].to_i + 1
  end
end
