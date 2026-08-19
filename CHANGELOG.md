# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [SemVer](https://semver.org/).

## [0.1.0] - 2026-08-19

### Added
- TSV deferral ledger with machine-decidable conditions (ISO due date / shell check).
- Engine `scripts/scan.sh`: scan / list / fire / done / kill / add / doctor.
- Ledger integrity red-line: malformed rows (column count, empty fields, bad status, bad
  due) surface as MALFORMED in scan, doctor, and list — never silently invisible.
- SessionStart ignition hook (`hooks/session-start-deferrals.sh`), silent when green.
- `install.sh` / `uninstall.sh`: idempotent settings.json registration with backup.
- 32 mutation self-checks (`tests/run.sh`), bash 3.2 + modern bash.
