include_recipe 'postgresql::replication'
include_recipe 'repmgr::install'
include_recipe 'repmgr::configure'

service 'repmgrd' do
  action [:enable, :start]
end
