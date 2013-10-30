include_recipe 'postgresql::apt_pgdg_postgresql'

resources('apt_repository[apt.postgresql.org]').components ['main', node['postgresql']['version']]
