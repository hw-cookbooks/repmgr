include_recipe 'repmgr'
package 'rsync'

link '/usr/local/bin/pg_ctl' do
  to File.join(%x{pg_config --bindir}.strip, 'pg_ctl')
  not_if do
    File.exists?('/usr/local/bin/pg_ctl')
  end
end

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
    command "#{node[:repmgr][:repmgr_bin]} -f #{node[:repmgr][:config_file_path]} master register --verbose"
    user 'postgres'
    not_if do
      output = %x{sudo -u postgres #{node[:repmgr][:repmgr_bin]} -f #{node[:repmgr][:config_file_path]} cluster show}
      master = output.split("\n").detect{|s| s.include?('master')}
      master.to_s.include?(node[:repmgr][:addressing][:self])
    end
  end
else
  master_node = find_master_node()

  unless(File.exists?(File.join(node[:postgresql][:config][:data_directory], 'recovery.conf')))
    # build our command in a string because it's long
    node.default[:repmgr][:addressing][:master] = master_node[:repmgr][:addressing][:self]
    clone_cmd = "#{node[:repmgr][:repmgr_bin]} " <<
      "-D #{node[:postgresql][:config][:data_directory]} " <<
      "-p #{node[:postgresql][:config][:port]} -U #{node[:repmgr][:replication][:user]} " <<
      "-R #{node[:repmgr][:system_user]} -d #{node[:repmgr][:replication][:database]} " <<
      "-w #{master_node[:repmgr][:replication][:keep_segments]} " <<
      "standby clone #{node[:repmgr][:addressing][:master]} --verbose"

    # use this to check for presence of 'backup in progress' before we start
    check_backup_in_progress_cmd = "ssh #{master_node[:repmgr][:addressing][:self]} -oStrictHostKeyChecking=no " <<
      "'ls #{File.join(master_node[:postgresql][:config][:data_directory], 'backup_label')}'"

    service 'postgresql-repmgr-stopper' do
      service_name 'postgresql'
      action :stop
    end

    execute 'ensure-halted-postgresql' do
      command "pkill postgres"
      ignore_failure true
    end

    directory 'scrub postgresql data directory' do
      action :delete
      recursive true
      path node[:postgresql][:config][:data_directory]
      only_if do
        File.directory?(node[:postgresql][:config][:data_directory])
      end
    end

    ruby_block 'clone standby node with retries' do
      block do
        # if a clone is already in progress, trigger retry
        result = Mixlib::ShellOut.new(
          check_backup_in_progress_cmd,
          :user => node['ninefold_app']['postgresql']['os_user'],
          :cwd => '/tmp'
        )
        result.run_command
        Chef::Log.debug "Clone in progress check: returned #{result.stdout || result.stderr}"
        raise 'Unable to start clone until other slave has completed - retrying' if result.exitstatus == 0

        # attempt clone operation, on failure trigger retry
        result = Mixlib::ShellOut.new(
          clone_cmd,
          :user => node['ninefold_app']['postgresql']['os_user'],
          :cwd => '/tmp'
        )
        result.run_command
        Chef::Log.debug "Clone command: returned #{result.stdout || result.stderr}"
        result.error!
      end
      action :create
      retries 20
      retry_delay 20
    end

    service 'postgresql-repmgr-starter' do
      service_name 'postgresql'
      action :start
      retries 2
    end

    ruby_block 'wait for consistent state to be achieved' do
      block do
        Chef::Log.warn 'Slaving delayed: waiting for postgresql hot_standby to achieve consistent state!'
        raise 'Failed to achieve consistent database state after slaving!'
      end
      not_if { postgresql_in_consistent_state? }
      action :nothing
      subscribes :create, 'service[postgresql-repmgr-starter]', :immediately
      retries 20
      retry_delay 20
      # NOTE: We need to give postgresql plenty of time to recover to a consistent state
    end

    execute 'register standby node' do
      command "#{node[:repmgr][:repmgr_bin]} -f #{node[:repmgr][:config_file_path]} standby register --verbose"
      user 'postgres'
      retries 10
      ignore_failure true
    end

    service 'repmgrd-setup-start' do
      service_name 'repmgrd'
      action :start
    end

    ruby_block 'confirm slave status' do
      block do
        Chef::Log.fatal "Slaving failed. Unable to detect self as standby: #{node[:repmgr][:addressing][:self]}"
        Chef::Log.fatal "OUTPUT: #{%x{sudo -u postgres repmgr -f #{node[:repmgr][:config_file_path]} cluster show}}"
        recovery_file = File.join(node[:postgresql][:config][:data_directory], 'recovery.conf')
        if(File.exists?(recovery_file))
          FileUtils.rm recovery_file
        end
        raise 'Failed to properly setup slaving!'
      end
      not_if do
        output = %x{sudo -u postgres repmgr -f #{node[:repmgr][:config_file_path]} cluster show}
        output.split("\n").detect{|s| s.include?('standby') && s.include?(node[:repmgr][:addressing][:self])}
      end
      action :nothing
      subscribes :create, 'service[repmgrd-setup-start]', :immediately
      retries 20
      retry_delay 20
      # NOTE: We want to give lots of breathing room here for catchup
    end

  end

  # add recovery manage here

  template File.join(node[:postgresql][:config][:data_directory], 'recovery.conf') do
    source 'recovery.conf.erb'
    mode 0644
    owner 'postgres'
    group 'postgres'
    notifies :restart, 'service[postgresql]', :immediately
    variables(
      :master_info => {
        :host => node[:repmgr][:addressing][:master],
        :port => master_node[:postgresql][:config][:port],
        :user => node[:repmgr][:replication][:user],
        :application_name => node.name
      }
    )
  end

  link File.join(node[:postgresql][:config][:data_directory], 'repmgr.conf') do
    to node[:repmgr][:config_file_path]
    not_if do
      File.exists?(
        File.join(node[:postgresql][:config][:data_directory], 'repmgr.conf')
      )
    end
  end

  # ensure we are a witness
  # TODO: Need HA flag
=begin
  execute 'register as witness' do
    command
  end
=end
end
