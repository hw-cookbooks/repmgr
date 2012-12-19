include_recipe 'repmgr'

if(node[:repmgr][:replication][:role] == 'master')
  execute 'register master node' do
    command "repmgr -f #{node[:repmgr][:config_file_path]} master register"
    user 'postgres'
    not_if "sudo -u postgres psql --dbname=#{node[:repmgr][:replication][:database]} -c '\\dn' | grep repmgr"
  end
else
  # TODO: Seach needs to be restricted to common environment
  unless(File.exists?(File.join(node[:postgresql][:config][:data_directory], 'recovery.conf')))
    master_node = search(:node, 'replication_role:master').first
    # build our command in a string because it's long
    clone_cmd = "#{node[:repmgr][:repmgr_bin]} " << 
      "-D #{node[:postgresql][:config][:data_directory]} " <<
      "-p #{node[:postgresql][:config][:port]} -U #{node[:repmgr][:replication][:user]} " <<
      "-R #{node[:repmgr][:system_user]} -d #{node[:repmgr][:replication][:database]} " <<
      "standby clone #{master_node.ipaddress}"

    service 'postgresql' do
      action :stop
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

    service 'postgresql-repmgr' do
      service_name 'postgresql'
      action :start
    end
  end
end
