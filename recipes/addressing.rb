
case node[:repmgr][:addressing][:detect].to_sym
when :cloud_private
  node.default[:repmgr][:addressing][:self] = node[:cloud][:private_ips].first
when :cloud_public
  node.default[:repmgr][:addressing][:self] = node[:cloud][:public_ips].first
end
