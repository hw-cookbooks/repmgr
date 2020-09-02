unless node['repmgr']['config']['node']
  nodes = discovery_all(
    'repmgr_config_node:*',
    raw_search: true,
    environment_aware: node['repmgr']['replication']['common_environment'],
    minimum_response_time: false,
    empty_ok: true
  )

  node.normal['repmgr']['config'][:node] = Array(nodes).map do |r_n|
    r_n[:repmgr][:config][:node].to_i
  end.max.to_i + 1
end
