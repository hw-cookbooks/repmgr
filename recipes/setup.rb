include_recipe 'repmgr'

if(node[:repmgr][:replication][:role] == 'master')
  execute 'register master node' do
    command "repmgr -f #{node[:repmgr][:config_file_path]} master register"
    not_if 'pgrep repmgrd'
  end
else
  # TODO: Seach needs to be restricted to common environment
  unless(File.exists?(File.join(node[:postgresql][:config][:data_directory], 'recovery.conf')))
    master_node = search(:node, 'replication_role:master').first
    if(master)
      # build our command in a string because it's long
      clone_cmd = "#{node[:repmgr][:repmgr_bin]} -D #{node[:postgresql][:config][:data_directory]} " <<
        "-p #{node[:postgresql][:config][:port]} -U #{node[:repmgr][:replication][:user]} " <<
        "-R #{node[:repmgr][:system_user]} -d #{node[:repmgr][:replication][:database]} " <<
        "standby clone #{master.ipaddress}"

      service 'postgresql' do
        action :stop
      end

      execute 'scrub postgresql data directory' do
        execute "rm -rf #{node[:postgresql][:config][:data_directory]}"
        only_if do
          File.directory?(node[:postgresql][:config][:data_directory])
        end
      end

      execute 'clone standby' do
        execute clone_cmd
      end

      service 'postgresql' do
        action :start
      end
    else
      Chef::Log.warn 'Failed to locate master node. Unable to clone database cluster!'
    end
  end
end
