include_recipe 'postgresql::apt_pgdg_postgresql'

resources('apt_repository[apt.postgresql.org]').components ['main', node['postgresql']['version']]

apt_preference 'pgdg_pin_1' do
  package_name '*'
  pin "release c=#{node['postgresql']['version']}"
  pin_priority '1000'
end

apt_preference 'pgdg_pin_2' do
  package_name '*'
  pin "release n=#{node['lsb']['codename']}-pgdg, v=#{node['postgresql']['version']}"
  pin_priority '600'
end
