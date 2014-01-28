directory File.dirname(node[:repmgr][:config_file_path]) do
  recursive true
end

template node[:repmgr][:config_file_path] do
  source 'repmgr.conf.erb'
  mode 0644
end

# Default out all the configuration values we want
node.default[:repmgr][:config][:cluster] = node[:repmgr][:cluster_name]
node.default[:repmgr][:config][:conninfo] = "host=#{node[:repmgr][:addressing][:self]} user=#{node[:repmgr][:replication][:user]} dbname=#{node[:repmgr][:replication][:database]}"
node.default[:repmgr][:config][:node_name] = node.name
node.default[:repmgr][:config][:rsync_options] = '--archive --checksum --compress --progress --rsh=ssh'
node.default[:repmgr][:config][:master_response_timeout] = 60
node.default[:repmgr][:config][:reconnect_attempts] = 6
node.default[:repmgr][:config][:reconnect_interval] = 10
node.default[:repmgr][:config][:failover] = 'manual'
node.default[:repmgr][:config][:priority] = -1
node.default[:repmgr][:config][:promote_command] = "repmgr standby promote -f #{node[:repmgr][:config_file_path]}"
node.default[:repmgr][:config][:follow_command] = "repmgr standby follow -f #{node[:repmgr][:config_file_path]} -W"
node.default[:repmgr][:config][:loglevel] = 'NOTICE'
node.default[:repmgr][:config][:logfacility] = 'STDERR'
