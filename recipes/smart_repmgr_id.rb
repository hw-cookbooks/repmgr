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
    cur_max = nil
    until(proper_id_aquired.call || tries >= node[:repmgr][:id_attempts])
      Chef::Log.info "Attempting to aquire proper repmgr ID for node! (note: this may require multiple attempts)"
      unless(cur_max)
        command = "psql -t -A -d #{node[:repmgr][:replication][:database]} -c 'select id from repmgr_#{node[:repmgr][:cluster_name]}.repl_nodes order by id desc limit 1'"
        cmd = Mixlib::ShellOut.new(command,
          :user => 'postgres'
        )
        cmd.run_command
        cmd.error!
        cur_max = cmd.stdout.strip.to_i
      end
      cur_max += 1
      node.set[:repmgr][:config][:node] = cur_max + 1
      t = Chef::Resource::Template.new("#{node[:repmgr][:config_file_path]} - #{node[:repmgr][:config][:node]}", run_context)
      t.path node[:repmgr][:config_file_path]
      t.source 'repmgr.conf.erb'
      t.cookbook 'repmgr'
      t.mode 0644
      t.run_action(:create)
      s = Chef::Resource::Service.new('repmgrd', run_context)
      s.supports(:status => true)
      s.run_action(:restart)
      Chef::Log.info 'Waiting to allow repmgrd to stand up...'
      sleep(5)
      tries += 1
    end
    if(tries >= node[:repmgr][:id_attempts])
      Chef::Log.fatal "Failed to aquire repmgr ID. Unable to join cluster!"
      raise 'Repmgr failed to join cluster'
    else
      Chef::Log.info "Repmgr aquired unique ID: #{node[:repmgr][:config][:node]}"
    end
  end
  not_if do
    proper_id_aquired.call
  end
end

ruby_block 'Clean previous IDs' do
  block do
    require 'pg'
    if(node[:repmgr][:replication_role] == 'master')
      master_node = node
    else
      master_node = discovery_search(
        'replication_role:master',
        :raw_search => true,
        :environment_aware => node[:repmgr][:replication][:common_environment],
        :minimum_response_time_sec => false,
        :empty_ok => false
      )
    end
    pg = PG::Connection.open(
      :host => node[:repmgr][:addressing][:master],
      :user => master_node[:repmgr][:replication][:user],
      :password => master_node[:repmgr][:replication][:user_password],
      :dbname => master_node[:repmgr][:replication][:database]
    )
    res = pg.exec(
      "SELECT id FROM repmgr_#{node[:repmgr][:cluster_name]}.repl_nodes WHERE name = $1 AND id != $2",
      [node.name, node[:repmgr][:config][:node]]
    )
    res.each_row do |row|
      Chef::Log.warn "Removing stale ID for PG node: name - #{node.name} id - #{row.first}"
      pg.exec("DELETE FROM repmgr_#{node[:repmgr][:cluster_name]}.repl_nodes where id = $1", [row.first])
    end
  end
  ignore_failure true
end
