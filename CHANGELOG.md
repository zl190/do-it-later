# Changelog

All notable changes to this project are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning: [SemVer](https://semver.org/).

## [0.3.0] - 2026-08-19

### Changed
- **Registry semantics.** Session start no longer injects the full wall of due rows
  (worst case measured ~5KB): it emits a one-line count signal, and demands disposition
  only when a high-stakes row tripped. `signal` verb added.
- New relevance surface: `topic:<regex>` rows come back with full context the moment the
  user's prompt or cwd matches — `match` verb + a UserPromptSubmit hook (auto-registered
  in the plugin; install.sh registers both hooks).
- Capture gate documented: hot-context ∧ ≤15min ∧ likely-needed → do it now, don't
  register.

## [0.2.0] - 2026-08-19

### Added
- `face` verb: the ledger as a self-contained HTML page (condition column, stakes chips,
  click-to-copy fire buttons; light theme with dark auto-variant). Lifecycle demo GIF.
- Plugin packaging: `.claude-plugin/plugin.json` + `hooks/hooks.json` +
  self-marketplace, so `claude plugin install do-it-later@do-it-later` ships the skill
  AND auto-registers the SessionStart hook (verified live: both-hook double-fire test).
- skills CLI compatibility (`npx skills add zl190/do-it-later`); install.sh now detects
  in-place installs and skips the self-referential symlink.
- Composition seams documented (inbound sweep API, outbound cold-start work orders,
  `PM_LEDGER` as the composition point) and per-repo todo_or_die mode with a CI recipe.

## [0.1.0] - 2026-08-19

### Added
- TSV deferral ledger with machine-decidable conditions (ISO due date / shell check).
- Engine `scripts/scan.sh`: scan / list / fire / done / kill / add / doctor.
- Ledger integrity red-line: malformed rows (column count, empty fields, bad status, bad
  due) surface as MALFORMED in scan, doctor, and list — never silently invisible.
- SessionStart ignition hook (`hooks/session-start-deferrals.sh`), silent when green.
- `install.sh` / `uninstall.sh`: idempotent settings.json registration with backup.
- 32 mutation self-checks (`tests/run.sh`), bash 3.2 + modern bash.
