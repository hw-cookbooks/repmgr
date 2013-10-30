#!/usr/bin/env bats

@test "it can run a benchmark" {
  run sudo -u postgres /usr/lib/postgresql/9.1/bin/pgbench -i -s 10 pgbench
  [ "$status" -eq 0 ]
}

@test "it has repmgr state data" {
  run sudo -u postgres psql -x -d pgbench -c "SELECT * FROM repmgr_an_cluster.repl_monitor"
  [ "$status" -eq 0 ]
}
