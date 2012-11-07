include_recipe 'repmgr'

directory File.dirname(node[:repmgr][:config_file_path])

template node[:repmgr][:config_file_path] do
  source 'repmgr.conf.erb'
  mode '0644'
end

node.set[:postgresql][:config][:wal_keep_segments] = node[:repmgr][:wal_files] if node[:repmgr][:wal_files]
