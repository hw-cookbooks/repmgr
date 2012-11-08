include_recipe 'postgresql::replication'
include_recipe 'repmgr::install'
include_recipe 'repmgr::configure'
include_recipe 'repmgr::setup'

service 'repmgrd' do
  action [:enable, :start]
end
