include_recipe 'repmgr'

if(node[:repmgr][:replication][:role] == 'master')
  execute 'grant repmgr schema create/usage on db' do
    command "psql -c \"grant create on database #{node[:repmgr][:replication][:database]} to #{node[:repmgr][:replication][:user]}\""
    user 'postgres'
    not_if "sudo -u postgres psql --dbname=#{node[:repmgr][:replication][:database]} -c '\\dn' | grep repmgr"
  end

  execute 'register master node' do
    command "repmgr -f #{node[:repmgr][:config_file_path]} master register"
    user 'postgres'
    not_if "sudo -u postgres psql --dbname=#{node[:repmgr][:replication][:database]} -c '\\dn' | grep repmgr"
  end
else
  # TODO: Seach needs to be restricted to common environment
  unless(File.exists?(File.join(node[:postgresql][:config][:data_directory], 'recovery.conf')))
    # build our command in a string because it's long
    clone_cmd = "#{node[:repmgr][:repmgr_bin]} -D #{node[:postgresql][:config][:data_directory]} " <<
      "-p #{node[:postgresql][:config][:port]} -U #{node[:repmgr][:replication][:user]} " <<
      "-R #{node[:repmgr][:system_user]} -d #{node[:repmgr][:replication][:database]} " <<
      "standby clone #{node[:repmgr][:replication][:hostname]}"

    service 'postgresql' do
      action :stop
    end

    execute 'scrub postgresql data directory' do
      command "rm -rf #{node[:postgresql][:config][:data_directory]}"
      user 'postgres'
      only_if do
        File.directory?(node[:postgresql][:config][:data_directory])
      end
    end

    execute 'clone standby' do
      user 'postgres'
      command clone_cmd
    end

    service 'postgresql' do
      action :start
    end
  end
end
