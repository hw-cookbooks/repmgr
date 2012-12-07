require 'securerandom'
include_recipe 'repmgr'

# create rep user and rep db

if( !node[:repmgr][:replication][:user_password] )
  pg_secret = SecureRandom.base64
  node.set[:repmgr][:replication][:user_password] = pg_secret
  node.save # make sure the password gets saved!
end

execute 'create replication user' do
  command "psql -c \"create user #{node[:repmgr][:replication][:user]} replication password '#{pg_secret}'\""
  user 'postgres'
  not_if "sudo -u postgres psql -c '\\du' | grep #{node[:repmgr][:replication][:user]}"
end

template '/var/lib/postgresql/.pgpass' do
  source 'pgpass.erb'
  owner node[:repmgr][:system_user]
  mode '0600'
end

key_bag = if(node[:repmgr][:encrypted_data_bag])
            Chef::EncryptedDataBagItem.load('repmgr', 'clone_key')
          else
            data_bag_item('repmgr', 'clone_key')
          end

directory '/var/lib/postgresql/.ssh' do
  mode '0755'
  owner node[:repmgr][:system_user]
  group node[:repmgr][:system_user]
end

if(node[:repmgr][:replication][:role] == 'master')
  file '/var/lib/postgresql/.ssh/authorized_keys' do
    content key_bag['public_key']
    mode '0644'
    owner node[:repmgr][:system_user]
    group node[:repmgr][:system_user]
  end
  node.set[:repmgr][:replication_role] = 'master'
  node.set[:postgresql][:config][:wal_level] = 'hot_standby'
  node.set[:postgresql][:config][:archive_mode] = true
  node.set[:postgresql][:config][:hot_standby] = true
  node.set[:postgresql][:config][:listen_addresses] = node[:repmgr][:replication][:listen_addresses]
  node.set[:postgresql][:config][:archive_command] = node[:repmgr][:replication][:archive_command]
  node.set[:postgresql][:config][:archive_timeout] = node[:repmgr][:replication][:archive_timeout]
  node.set[:postgresql][:config][:max_wal_senders] = node[:repmgr][:replication][:max_senders]
  node.set[:postgresql][:config][:wal_keep_segments] = node[:repmgr][:replication][:keep_segments]
else
  file '/var/lib/postgresql/.ssh/id_rsa' do
    content key_bag['private_key']
    mode '0644'
    owner node[:repmgr][:system_user]
    group node[:repmgr][:system_user]
  end
  node.set[:postgresql][:replication_role] = 'slave'
  node.set[:postgresql][:config][:wal_level] = 'hot_standby'
  node.set[:postgresql][:config][:hot_standby_feedback] = node[:repmgr][:replication][:standby_feedback]
  node.set[:postgresql][:config][:max_standby_streaming_delay] = node[:repmgr][:replication][:max_streaming_delay]
end

include_recipe 'repmgr'
directory File.dirname(node[:repmgr][:config_file_path])

template node[:repmgr][:config_file_path] do
  source 'repmgr.conf.erb'
  mode '0644'
end

node.set[:postgresql][:config][:wal_keep_segments] = node[:repmgr][:wal_files] if node[:repmgr][:wal_files]
