include_recipe 'postgresql::apt_pgdg_postgresql'

postgresql_apt = resources('apt_repository[apt.postgresql.org]')
postgresql_apt.components ['main', node['postgresql']['version']]
postgresql_apt.run_action(:add)

pin1 = apt_preference 'pgdg_pin_1' do
  package_name '*'
  pin "release c=#{node['postgresql']['version']}"
  pin_priority '1000'
end
pin1.run_action(:add)

pin2 = apt_preference 'pgdg_pin_2' do
  package_name '*'
  pin "release n=#{node['lsb']['codename']}-pgdg, v=#{node['postgresql']['version']}"
  pin_priority '600'
end
pin2.run_action(:add)
