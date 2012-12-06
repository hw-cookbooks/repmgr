include_recipe 'build-essential'

# We want pg_config binary available at compile time
p = package 'libpq-dev' do
  action :nothing
end
p.run_action(:install)

(node[:repmgr][:packages][:dependencies] + Array(node[:repmgr][:packages][:pg_dev])).each do |pkg|
  package pkg
end

r_url = File.join(node[:repmgr][:base_uri], "repmgr-#{node[:repmgr][:version]}.tar.gz")
r_local = File.join(node[:repmgr][:build_dir], File.basename(r_url))
pg_bindir = %x{pg_config --bindir}.strip

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
  cwd r_local.sub('.tar.gz', '')
  creates File.join(pg_bindir, 'repmgr')
end

# Ensure commands are in default path!
case node.platform_family
when 'debian'
  execute "add repmgr to default paths" do
    command "update-alternatives --install /usr/bin/repmgr repmgr #{File.join(pg_bindir, 'repmgr')} 10"
    not_if do
      %x{update-alternatives --display repmgr}.split("\n").last.to_s.strip.split(' ').last.to_s.gsub(%r{('|\.$)}, '') == File.join(pg_bindir, 'repmgr')
    end
  end
  execute "add repmgrd to default paths" do
    command "update-alternatives --install /usr/bin/repmgrd repmgrd #{File.join(pg_bindir, 'repmgrd')} 10"
    not_if do
      %x{update-alternatives --display repmgrd}.split("\n").last.to_s.strip.split(' ').last.to_s.gsub(%r{('|\.$)}, '') == File.join(pg_bindir, 'repmgrd')
    end
  end
when 'rhel'
  # TODO
end

template '/etc/init.d/repmgrd' do
  source 'repmgrd.initd.erb'
  mode '0755'
  variables(
            :bin_path => node[:repmgr][:repmgrd_bin],
            :el => node.platform_family == 'rhel'
            )
end
