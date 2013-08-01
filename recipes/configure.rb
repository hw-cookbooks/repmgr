require 'securerandom'
include_recipe 'database'
include_recipe 'postgresql::ruby'
include_recipe 'repmgr::dumb_repmgr_id'

# create rep user and rep db

if(node[:repmgr][:replication][:role] == 'master')
  unless(node[:repmgr][:replication][:user_password])
    pg_pass = SecureRandom.base64
    node.set[:repmgr][:replication][:user_password] = pg_pass
    node.save # make sure the password gets saved!
  end
else
  pass_assign = resources(:bash => 'assign-postgres-password')
  pass_assign.action :nothing

  master_node = discovery_search(
    'replication_role:master',
    :environment_aware => node[:repmgr][:replication][:common_environment],
    :minimum_response_time_sec => false,
    :raw_search => true,
    :empty_ok => false
  )
  if(master_node)
    pg_pass = master_node[:repmgr][:replication][:user_password]
    # Cache the password so that if the node is promoted to master, we don't lose our
    # passwords
    node.set[:repmgr][:replication][:user_password] = pg_pass
    node.save
  end
end

template File.join(node[:repmgr][:pg_home], '.pgpass') do
  source 'pgpass.erb'
  owner node[:repmgr][:system_user]
  variables(
    :password => pg_pass || node[:repmgr][:replication][:user_password]
  )
  mode 0600
end


if(node[:repmgr][:data_bag][:encrypted])
  if(node[:repmgr][:data_bag][:secret])
    secret = Chef::EncryptedDataBagItem.load_secret(node[:repmgr][:data_bag][:secret])
  end
  key_bag = Chef::EncryptedDataBagItem.load(
    node[:repmgr][:data_bag][:name],
    node[:repmgr][:data_bag][:item],
    secret
  )
else
  key_bag = data_bag_item(node[:repmgr][:data_bag][:name], node[:repmgr][:data_bag][:item])
end

directory File.join(node[:repmgr][:pg_home], '.ssh') do
  mode 0755
  owner node[:repmgr][:system_user]
  group node[:repmgr][:system_user]
end

file File.join(node[:repmgr][:pg_home], '.ssh/authorized_keys') do
  content key_bag['public_key']
  mode 0644
  owner node[:repmgr][:system_user]
  group node[:repmgr][:system_user]
end

file File.join(node[:repmgr][:pg_home], '.ssh/id_rsa') do
  content key_bag['private_key']
  mode 0600
  owner node[:repmgr][:system_user]
  group node[:repmgr][:system_user]
end

template File.join(node[:repmgr][:pg_home], '.ssh/config') do
  source 'ssh_config.erb'
  mode 0644
  owner node[:repmgr][:system_user]
  group node[:repmgr][:system_user]
  variables( :hosts => node[:repmgr][:ssh_ignore_hosts] )
  only_if { node[:repmgr][:ssh_ignore_hosts_enabled] }
end

include_recipe 'repmgr::repmgr_conf'

if(node[:repmgr][:replication][:role] == 'master')

  conninfo = {
    :host => '127.0.0.1',
    :port => node[:postgresql][:config][:port],
    :username => 'postgres',
    :password => node[:postgresql][:password][:postgres]
  }

  postgresql_database node[:repmgr][:replication][:database] do
    connection conninfo
    connection_limit '-1'
  end

  postgresql_database_user node[:repmgr][:replication][:user] do
    connection conninfo
    password node[:repmgr][:replication][:user_password]
    database_name node[:repmgr][:replication][:database]
    action [:create, :grant]
    notifies :run, 'execute[Update replication user role]', :immediately
  end

  execute 'Update replication user role' do
    command "psql -c \"alter role #{node[:repmgr][:replication][:user]} with superuser replication\""
    action :nothing
    user 'postgres'
  end

  # Node role!
  node.set[:repmgr][:replication_role] = 'master'
  # Configurations!
  node.set[:postgresql][:config][:wal_level] = 'hot_standby'
  node.set[:postgresql][:config][:archive_mode] = true
  node.set[:postgresql][:config][:listen_addresses] = node[:repmgr][:replication][:listen_addresses]
  node.set[:postgresql][:config][:hot_standby] = true

  node.set[:repmgr][:addressing][:master] = node[:repmgr][:addressing][:self]

else
  node.set[:repmgr][:replication_role] = 'slave'
  node.set[:postgresql][:config][:hot_standby] = node[:repmgr][:readonly_slave]
  node.set[:postgresql][:config][:wal_level] = 'hot_standby'
  node.set[:postgresql][:config][:hot_standby_feedback] = node[:repmgr][:replication][:standby_feedback]
  node.set[:postgresql][:config][:max_standby_streaming_delay] = node[:repmgr][:replication][:max_streaming_delay]
  node.default[:postgresql][:config][:listen_addresses] = node[:repmgr][:replication][:listen_addresses]
  
  if(master_node)
    node.default[:repmgr][:addressing][:master] = master_node[:repmgr][:addressing][:self]
    file '/var/lib/postgresql/.ssh/known_hosts' do
      content %x{ssh-keyscan #{node[:repmgr][:addressing][:master]}}
    end
  end
end

node.set[:postgresql][:config][:archive_command] = node[:repmgr][:replication][:archive_command]
node.set[:postgresql][:config][:archive_timeout] = node[:repmgr][:replication][:archive_timeout]
node.set[:postgresql][:config][:max_wal_senders] = node[:repmgr][:replication][:max_senders]
node.set[:postgresql][:config][:wal_keep_segments] = node[:repmgr][:replication][:keep_segments]

# HBA
node.default[:postgresql][:pg_hba] = [
  {:type => 'hostssl', :db => node[:repmgr][:replication][:database], :user => node[:repmgr][:replication][:user], :addr => node[:repmgr][:master_allow_from], :method => 'md5'},
  {:type => 'hostssl', :db => 'replication', :user => node[:repmgr][:replication][:user], :addr => node[:repmgr][:master_allow_from], :method => 'md5'}
] + node[:postgresql][:pg_hba]
