default[:repmgr][:addressing][:self] = node[:ipaddress]
default[:repmgr][:addressing][:master] = nil
default[:repmgr][:base_uri] = 'http://www.repmgr.org/download'
default[:repmgr][:version] = '2.0beta1'
default[:repmgr][:github_branch] = 'bugfix/standby-follow-user' #'REL2_0_STABLE'
default[:repmgr][:github_base] = 'http://github.com/chrisroberts/repmgr/archive/' #'http://github.com/2ndQuadrant/repmgr/archive/'
default[:repmgr][:enable_github_build] = true
default[:repmgr][:build_dir] = '/var/cache/repmgr'
default[:repmgr][:id_attempts] = 5
default[:repmgr][:install_method] = 'source'
default[:repmgr][:package_name] = nil
# TODO: pkg-build
default[:repmgr][:data_bag][:name] = 'repmgr'
default[:repmgr][:data_bag][:item] = 'clone_key'
default[:repmgr][:data_bag][:encrypted] = true
default[:repmgr][:data_bag][:secret] = Chef::EncryptedDataBagItem::DEFAULT_SECRET_FILE
default[:repmgr][:packages][:pg_dev] = "postgresql-server-dev-#{node[:postgresql][:version]}"
default[:repmgr][:packages][:dependencies] = %w(libxslt1-dev libpam0g-dev libedit-dev rsync)
default[:repmgr][:readonly_slaves] = true
default[:repmgr][:repmgrd_bin] = '/usr/bin/repmgrd'
default[:repmgr][:repmgr_bin] = '/usr/bin/repmgr'
default[:repmgr][:config_file_path] = '/etc/repmgr/repmgr.conf'
default[:repmgr][:cluster_name] = 'an_cluster'
default[:repmgr][:system_user] = 'postgres'
default[:repmgr][:ssh_ignore_hosts_enabled] = false
default[:repmgr][:ssh_ignore_hosts] = '192.168.0.*'
default[:repmgr][:master_allow_from] = '0.0.0.0/0'
default[:repmgr][:pg_home] = '/var/lib/postgresql'
default[:repmgr][:readonly_slave] = true
default[:repmgr][:id_generator_splay] = 30
default[:repmgr][:replication][:role] = 'master'
default[:repmgr][:replication][:wal_level] = 'hot_standby'
default[:repmgr][:replication][:archive_command] = '/bin/true'
default[:repmgr][:replication][:archive_timeout] = 60
default[:repmgr][:replication][:max_senders] = 5
default[:repmgr][:replication][:keep_segments] = 2000
default[:repmgr][:replication][:streaming_delay] = -1
default[:repmgr][:replication][:listen_addresses] = '*'
default[:repmgr][:replication][:user] = 'replication_user'
default[:repmgr][:replication][:database] = 'replication_db'
default[:repmgr][:replication][:standby_feedback] = true
default[:repmgr][:replication][:hostname] = 'localhost'
default[:repmgr][:replication][:common_environment] = true

default[:repmgr][:init][:enable_monitoring] = false


default[:repmgr][:wal_files] = 2000
default[:repmgr][:config] = {}
