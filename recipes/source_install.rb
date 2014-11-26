require 'uri'

node.set[:build_essential][:compiletime] = true

include_recipe 'build-essential'

# We want pg_config binary available at compile time
p = package 'libpq-dev' do
  action :nothing
end
p.run_action(:install)

node.default[:repmgr][:pg_bin_dir] = %x{pg_config --bindir}.strip

(node[:repmgr][:packages][:dependencies] + Array(node[:repmgr][:packages][:pg_dev])).each do |pkg|
  package pkg
end

if node[:postgresql][:version] == '9.3'
  node.default[:repmgr][:enable_github_build] = false
end

if(node[:repmgr][:enable_github_build])
  file_name = "repmgr-#{node[:repmgr][:github_branch]}.tar.gz"
  node.default[:repmgr][:download_url] = URI.join(node[:repmgr][:github_base], "#{node[:repmgr][:github_branch]}.tar.gz").to_s
else
  file_name = "repmgr-#{node[:repmgr][:version]}.tar.gz"
  node.default[:repmgr][:download_url] = URI.join(node[:repmgr][:base_uri], file_name).to_s
end

r_local = File.join(node[:repmgr][:build_dir], file_name.gsub('/', '-'))
r_path  = r_local.sub('.tar.gz', '')    
    
directory node[:repmgr][:build_dir]

    remote_file r_local do
        source node[:repmgr][:download_url]
      if node[:repmgr][:download_checksum] && node[:postgresql][:version] == '9.2'
        checksum node[:repmgr][:download_checksum]
        action :create
      else
       action :create_if_missing
      end
    end

execute "unpack #{File.basename(r_local)}" do
  command "tar xzf #{r_local}"
  cwd File.dirname(r_local)
  creates r_path
end

if node[:postgresql][:version] == '9.2'
  %w(repmgr.h check_dir.c).each do |c_file|
    cookbook_file File.join(r_path, c_file) do
      action :create
    end
  end
end


execute "configure repmgr v#{node[:repmgr][:version]}" do
  command "make USE_PGXS=1 install"
  cwd r_path
  creates File.join(node[:repmgr][:pg_bin_dir], 'repmgr')
end

# Ensure commands are in default path!
case node.platform_family
when 'debian'
  execute "add repmgr to default paths" do
    command "update-alternatives --install /usr/bin/repmgr repmgr #{File.join(node[:repmgr][:pg_bin_dir], 'repmgr')} 10"
    not_if do
      %x{update-alternatives --display repmgr}.split("\n").last.to_s.strip.split(' ').last.to_s.gsub(%r{('|\.$)}, '') == File.join(node[:repmgr][:pg_bin_dir], 'repmgr')
    end
  end
  execute "add repmgrd to default paths" do
    command "update-alternatives --install /usr/bin/repmgrd repmgrd #{File.join(node[:repmgr][:pg_bin_dir], 'repmgrd')} 10"
    not_if do
      %x{update-alternatives --display repmgrd}.split("\n").last.to_s.strip.split(' ').last.to_s.gsub(%r{('|\.$)}, '') == File.join(node[:repmgr][:pg_bin_dir], 'repmgrd')
    end
  end
when 'rhel'
  # TODO
end

case node[:repmgr][:init][:type].to_s
when 'runit'
  include_recipe 'runit'
  runit_service 'repmgrd' do
    default_logger true
    run_template_name 'repmgrd'
  end
when 'upstart'
  raise "Not currently supported init type (upstart)"
else
  template '/etc/init.d/repmgrd' do
    source 'repmgrd.initd.erb'
    mode '0755'
    variables(
      :el => node.platform_family == 'rhel'
    )
    if(File.exists?('/etc/init.d/repmgrd'))
      notifies :restart, 'service[repmgrd]'
    end
  end
end
