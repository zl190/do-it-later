# Security

## Threat model (read this before installing)

Two honest facts about what this tool does on your machine:

1. **`install.sh` edits `~/.claude/settings.json`** — additively (one SessionStart hook
   entry), idempotently, with a timestamped backup first, and `uninstall.sh` reverses it.
   Read the script before running it; it is short on purpose.
2. **`check` conditions are shell commands executed by `scan`** — which runs at every
   session start once the hook is installed. The ledger is a local file you own, but that
   means: **anything that can write your ledger can schedule command execution.** Treat
   ledger rows like you treat your shell rc files. Never add a row you didn't read, and be
   suspicious of any tool, agent, or document that asks you to add one. `scan` runs checks
   with your privileges; there is no sandbox.

Mitigations in the engine: `add` rejects ids outside `[A-Za-z0-9._-]`, refuses tabs in
fields, and refuses condition-less rows; `validate_ledger` reds malformed rows instead of
silently skipping them. None of that makes an untrusted check command safe — review what
goes in the `check` column.

## Supported versions

The latest tagged release and `main`.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting on this repository (Security tab → Report a
vulnerability). Please include a minimal reproduction (a ledger fixture + the command run).
You should hear back within a week.
