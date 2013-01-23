include_recipe 'repmgr'

if(node[:repmgr][:replication][:role] == 'master')
  # TODO: If changed master is detected should we force registration or
  #       leave that to be hand tuned?
  ruby_block 'kill run if master already exists!' do
    block do
      raise 'Different node is already identified as PostgreSQL master!'
    end
    only_if do
      output = %x{sudo -u postgres repmgr -f #{node[:repmgr][:config_file_path]} cluster show}
      master = output.split("\n").detect{|s| s.include?('master')}
      !master.to_s.empty? && !master.to_s.include?(node[:repmgr][:addressing][:self])
    end
  end

  execute 'register master node' do
    command "repmgr -f #{node[:repmgr][:config_file_path]} master register"
    user 'postgres'
    not_if do
      output = %x{sudo -u postgres repmgr -f #{node[:repmgr][:config_file_path]} cluster show}
      master = output.split("\n").detect{|s| s.include?('master')}
      master.to_s.include?(node[:repmgr][:addressing][:self])
    end
  end
else
  unless(File.exists?(File.join(node[:postgresql][:config][:data_directory], 'recovery.conf')))
    master_node = discovery_search(
      'repmgr_replication_role:master',
      :raw_search => true,
      :environment_aware => node[:repmgr][:replication][:common_environment],
      :minimum_response_time_sec => false,
      :empty_ok => false
    )
    # build our command in a string because it's long
    node.default[:repmgr][:addressing][:master] = master_node[:ipaddress]
    clone_cmd = "#{node[:repmgr][:repmgr_bin]} " << 
      "-D #{node[:postgresql][:config][:data_directory]} " <<
      "-p #{node[:postgresql][:config][:port]} -U #{node[:repmgr][:replication][:user]} " <<
      "-R #{node[:repmgr][:system_user]} -d #{node[:repmgr][:replication][:database]} " <<
      "standby clone #{node[:repmgr][:addressing][:master]}"

    service 'postgresql-repmgr-stopper' do
      service_name 'postgresql'
      action :stop
    end

    execute 'ensure-halted-postgresql' do
      command "kill `cat #{node[:postgresql][:config][:external_pid_file]}`"
      only_if "kill -0 `cat #{node[:postgresql][:config][:external_pid_file]}`"
    end

    directory 'scrub postgresql data directory' do
      action :delete
      recursive true
      path node[:postgresql][:config][:data_directory]
      only_if do
        File.directory?(node[:postgresql][:config][:data_directory])
      end
    end

    execute 'clone standby' do
      user 'postgres'
      command clone_cmd
    end
    
    service 'postgresql-repmgr-starter' do
      service_name 'postgresql'
      action :start
    end

  end
end
