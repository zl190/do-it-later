# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

A prospective-memory ledger for agents: deferred commitments live in a TSV ledger
(`~/.claude/memory/deferrals.tsv` at runtime) with machine-decidable conditions, and a
SessionStart hook trips due rows back into conversations. Read `SKILL.md` for the full
data contract before changing anything.

## Commands

```sh
bash tests/run.sh          # the test suite — 32 mutation self-checks, must stay green
bash scripts/scan.sh scan  # the engine (uses PM_LEDGER env override)
```

## Hard rules

- **Never touch a user's real ledger in tests or experiments.** Always set
  `PM_LEDGER=$(mktemp -d)/deferrals.tsv`. The suite already does this; keep it that way.
- **Mutation discipline**: every behavioral change needs a red-side AND a green-side test
  (the thing that should fire fires; the thing that shouldn't doesn't). A check that can't
  go red when the code is broken does not count as a test.
- **Portability floor**: bash 3.2 (macOS system shell) + POSIX awk. No GNU-only flags,
  no `sed -i` without suffix, no date arithmetic (date comparisons are ISO-lexicographic
  on purpose). CI runs the suite on ubuntu + macOS system bash.
- **Ledger integrity is load-bearing**: rows must never become silently invisible.
  `read_rows` (well-formed only) and `validate_ledger` (reds everything else) are a pair:
  if you change one, change the other, and add a MALFORMED test.
- **Date firing stays always-on.** No environment guards, no opt-in flag. (Lineage lesson:
  eslint's expiring-todo-comments ships `checkDates: false`, a flagship semantic that is
  dead by default. We do the opposite on purpose.)
- `install.sh`/`uninstall.sh` edit `~/.claude/settings.json`; test changes only against a
  sandbox (`CLAUDE_DIR=$(mktemp -d)`), keep them idempotent, keep the backup step.

## Scope (say no for the maintainer)

Not a todo app (no priorities, no scheduling UI), not retrospective memory, not a sync
service. PRs adding those are out of scope regardless of quality.
