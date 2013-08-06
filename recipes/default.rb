include_recipe 'repmgr::composite_attributes'

package 'rsync'

include_recipe 'repmgr::addressing'
include_recipe 'repmgr::install'
include_recipe 'repmgr::configure'
include_recipe 'repmgr::setup'
include_recipe 'repmgr::smart_repmgr_id'

service 'repmgrd' do
  action node[:repmgr][:init][:type].to_s == 'runit' ? :start : [:enable, :start]
end
