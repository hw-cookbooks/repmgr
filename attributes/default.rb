default[:repmgr][:base_uri] = 'http://www.repmgr.org/download'
default[:repmgr][:version] = '1.2.0'
default[:repmgr][:build_dir] = '/var/cache/repmgr'
default[:repmgr][:packages][:pg_dev] = 'postgresql-server-dev-9.1'
default[:repmgr][:packages][:dependencies] = %w(libxslt1-dev libpam0g)
