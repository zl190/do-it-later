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

# v0.3: the ledger is a registry, not a todo list. Session start emits a ONE-LINE
# count signal (never the full wall); context is pulled on demand or at relevance
# (see the user-prompt match hook). Disposition is demanded only for high stakes.
out="$(bash "$SCAN" signal 2>/dev/null)"
rc=$?

if [ "$rc" -eq 1 ]; then
  printf '%s\n' "$out"
fi
exit 0
