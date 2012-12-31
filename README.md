# Repmgr

Installs and configures repmgr to enable and monitor
PostgreSQL replication.

# Usage

Nodes should be labeled as master or slave. Generally
done within a role:

```ruby
name 'master_role'
run_list('role[pg]', 'recipe[repmgr]')
override_attributes(
  :repmgr => {
    :replication => {
      :role => 'master'
    }
  }
)
```

```ruby
name 'slave_role'
run_list('role[pg]', 'recipe[repmgr]')
override_attributes(
  :repmgr => {
    :replication => {
      :role => 'slave'
    }
  }
)
```
Slaves will search for master node within their current environment
and sync to that master. By default slave nodes will allow read-only
access.

## Infos
* Repository: https://github.com/hw-cookbooks/repmgr
* IRC: Freenode @ #heavywater
