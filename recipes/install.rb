case node[:repmgr][:install_method]
when 'source'
  include_recipe 'repmgr::source_install'
when 'package'
  Array(node[:repmgr][:package_name]).each do |rep_pkg|
    package rep_pkg
  end
else
  raise 'Invalid installation method selected for repmgr. Must be source or package.'
end
