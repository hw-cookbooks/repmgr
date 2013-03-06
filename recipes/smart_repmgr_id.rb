include_recipe 'postgresql::ruby'

proper_id_aquired = lambda do
  output = %x{sudo -u postgres #{node[:repmgr][:repmgr_bin]} -f #{node[:repmgr][:config_file_path]} cluster show}
  !!output.split("\n").detect do |n| 
    n.include?(node[:ipaddress]) || n.include?(node[:repmgr][:addressing][:self])
  end
end

ruby_block 'Confirm repmgr ID for node' do
  block do
    tries = 0
    until(proper_id_aquired.call || tries >= node[:repmgr][:id_attempts])
      Chef::Log.info "Attempting to aquire proper repmgr ID for node! (note: this may require multiple attempts)"
      cur_max = %x{sudo -u postgres psql -t -A -d #{node[:repmgr][:replication][:database]} -c 'select id from repmgr_#{node[:repmgr][:cluster_name]}.repl_nodes order by id desc limit 1'}.strip.to_i
      node.set[:repmgr][:repmgr_node_id] = cur_max + 1
      t = Chef::Resource::Template.new(node[:repmgr][:config_file_path], run_context)
      t.source 'repmgr.conf.erb'
      t.cookbook 'repmgr'
      t.mode 0644
      t.run_action(:create)
      s = Chef::Resource::Service.new('repmgrd', run_context)
      s.run_action(:start)
      Chef::Log.info 'Waiting to allow repmgrd to stand up...'
      sleep(5)
      tries += 1
    end
    if(tries >= node[:repmgr][:id_attempts])
      Chef::Log.fatal "Failed to aquire repmgr ID. Unable to join cluster!"
      raise 'Repmgr failed to join cluster'
    else
      Chef::Log.info "Repmgr aquired unique ID: #{node[:repmgr][:repmgr_node_id]}"
    end
  end
  not_if do
    proper_id_aquired.call
  end
end
