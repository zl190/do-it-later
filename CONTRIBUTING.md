# Contributing

Small tool, sharp scope — read [AGENTS.md](AGENTS.md) first: it carries the invariants
(mutation-test discipline, bash 3.2 + POSIX awk floor, ledger-integrity pairing, always-on
date firing) that apply to humans exactly as much as to agents.

- Before a PR: `bash tests/run.sh` green, and every behavioral change adds a red-side AND a
  green-side test.
- Out of scope regardless of quality: todo-app features (priorities, scheduling UI),
  retrospective memory, sync services.
- Bug reports: use the issue form; paste real `scan`/`doctor` output against a fixture
  ledger (`PM_LEDGER=$(mktemp -d)/deferrals.tsv`), never your real one.
