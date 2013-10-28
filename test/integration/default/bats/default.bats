#!/usr/bin/env bats

@test "it can create a db" {
  run sudo -u postgres createdb pgbench
  [ "$status" -eq 0 ]
}

@test "it can run a benchmark" {
  run sudo -u postgres /usr/lib/postgresql/9.1/bin/pgbench -i -s 10 pgbench
  [ "$status" -eq 0 ]
}

@test "it has a replication status" {
  run sudo -u postgres psql -x -d pgbench -c "SELECT * FROM repmgr_test.repl_status"
  [ "$status" -eq 0 ]
}
