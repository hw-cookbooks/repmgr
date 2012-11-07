default[:repmgr][:base_uri] = 'http://www.repmgr.org/download'
default[:repmgr][:version] = '1.2.0'
default[:repmgr][:build_dir] = '/var/cache/repmgr'
# TODO: RHEL based packages
default[:repmgr][:packages][:pg_dev] = 'postgresql-server-dev-9.1'
default[:repmgr][:packages][:dependencies] = %w(libxslt1-dev libpam0g-dev libedit-dev)
default[:repmgr][:repmgrd_bin] = '/usr/bin/repmgrd'
default[:repmgr][:config_file_path] = '/etc/repmgr/repmgr.conf'
