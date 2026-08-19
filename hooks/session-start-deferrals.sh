#!/usr/bin/env bash
# session-start-deferrals.sh — do-it-later's A-grade ignition surface (SessionStart,
# a path every session must walk). Injection discipline: a green ledger = zero
# output, zero tokens; only due/invalid rows inject. Always exits 0 — the surface
# trips commitments back into the conversation, it never blocks a session.
set -u

# drain the SessionStart JSON payload when present (manual runs have a tty)
if [ ! -t 0 ]; then cat >/dev/null 2>&1 || true; fi

SELF="$(cd "$(dirname "$0")" && pwd)"
SCAN="$SELF/../scripts/scan.sh"
[ -f "$SCAN" ] || exit 0

out="$(bash "$SCAN" scan 2>/dev/null)"
rc=$?

if [ "$rc" -eq 1 ]; then
  printf '[pm-ledger] The deferral ledger has due/invalid commitments. Each one MUST be dispositioned this session: do it (fire -> done) / re-condition it (with a reason) / kill it (with a reason). Do not silently slide past — that is the exact failure this ledger exists to prevent.\n'
  printf '%s\n' "$out"
  printf 'verbs: %s {list | fire <id> | done <id> | kill <id> <reason>}\n' "$SCAN"
fi
exit 0
