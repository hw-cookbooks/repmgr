## v0.2.2
* Ensure daemon is started before slave confirmation
* Force daemon restart when init is updated

## v0.2.0
* Update repmgr version installed
* Allow custom source location
* Clean up configuration generation
* Always use `addressing` attributes
* Allow monitoring to be enabled in init script
* Add support for runit to manage `repmgrd`
* Clean out cluster tables if needed
* Remove duplicate attributes
* Support modified versions of postgresql
* Reduce keep segments to 500 by default

## v0.1.2
* Fix discovery version restriction

## v0.1.1
* Update repmgr node id implementation
* Allow customized addressing when node[:ipaddress] is not desired
* Ensure Postgresql is dead before starting sync (fixes stale pid issue)
* Allow repmgr to be installed via package

## v0.1.0
* Initial release
