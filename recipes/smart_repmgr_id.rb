include_recipe 'postgresql::ruby'

proper_id_aquired = lambda do
  output = %x{sudo -u postgres repmgr -f #{node[:repmgr][:config_file_path]} cluster show}
  !!output.split("\n").detect{|n| n.include?(node[:ipaddress])}
end

ruby_block 'Confirm repmgr ID for node' do
  block do
    until(proper_id_aquired.call)
      Chef::Log.info "Attempting to aquire proper repmgr ID for node! (note: this may require multiple attempts)"
      cur_max = %x{sudo -u postgres psql -t -A -d #{node[:repmgr][:replication][:database]} -c 'select id from repmgr_#{node[:repmgr][:cluster_name]}.repl_nodes order by id desc limit 1'}.strip.to_i
      node.set[:repmgr][:repmgr_node_id] = cur_max + 1
      t = Chef::Resource::Template.new(node[:repmgr][:config_file_path], run_context)
      t.source 'repmgr.conf.erb'
      t.mode 0644
      t.run_action(:create)
      %x{sudo -u postgres repmgr -f #{node[:repmgr][:config_file_path]} #{node[:repmgr][:replication][:role] == 'master' ? 'master' : 'standby'} register}
    end
  end
  not_if do
    proper_id_aquired.call
  end
end
