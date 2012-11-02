include_recipe 'build-essential'

default[:repmgr][:packages][:pg_dev] = 'postgresql-server-dev-9.1'
default[:repmgr][:packages][:dependencies] = %w(libxslt1-dev libpam0g)

(node[:repmgr][:packages][:dependencies] + Array(node[:repmgr][:packages][:pg_dev])).each do |pkg|
  package pkg
end

r_url = File.join(node[:repmgr][:base_uri], "repmgr-#{node[:repmgr][:version]}.tar.gz")
r_local = File.join(node[:repmgr][:build_dir], File.basename(r_url))
pg_bin = %x{pg_config --bindir}.strip

directory node[:repmgr][:build_dir]

remote_file r_local do
  source r_url
  action :create_if_missing
end

execute "unpack #{File.basename(r_local)}" do
  command "tar xzf #{r_local}"
  cwd File.dirname(r_local)
  creates r_local.sub('.tar.gz', '')
end

execute "configure repmgr v#{node[:repmgr][:version]}" do
  command "make USE_PGXS=1 install"
  cwd File.dirname(r_local)
  creates File.join(pg_bindir, 'repmgr')
end

template '/etc/init.d/repmgrd' do
  source 'repmgrd.init.erb'
  variables(
    :bin_path => File.join(pg_bindir, 'repmgr'),
    :el => node.platform_family == 'rhel'

  )
end

service 'repmgrd' do
  action [:enable, :start]
end
