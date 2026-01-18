# Changelog

## 1.0.3 - 2026-01-18

### Added

- Added `CHANGELOG.md`
- Added `config/adminer-plugins.php`
- Added `setenforce Permissive` and firewall commands to unblock localhost websites.

### Changed

- Updated YAML array format in `settings.yaml`.
    - Added `:id` to all `:forwarded_ports`.
- Updated `Vagrantfile` by adding local variables.
    - Modernized path in the `YAML.load_file()` call.
- Replaced `FORWARDED_PORT_80` variable with `HOST_HTTP_PORT` in 3 files.
    - Updated `provision.sh`, `adminer.conf`, `virtualhost.conf` with new variable name.
- Modified the version section of `provision.sh` for the section title and the Apache version output.
- Updated the last section of `README.md`.
- Updated `config/adminer.php`.

### Fixed

- Updated Adminer to version 5+ plugin code and files.

### Removed

- Removed SSL certificates and this VM hosting HTTPS localhost

## 1.0.2 - 2023-01-16

### Changed

- Set remi-release-8.5 for PHP to work.
- Updated Adminer.

## 1.0.1 - 2021-04-26

## Added

- Added SSH forwarded ports to `settings.yaml`.
- Added `:php_error_reporting` to `settings.yaml`.

### Changed

- Modified `Vagrantfile` and `provision.sh`.

## 1.0.0 - 2021-04-15

_First release_
