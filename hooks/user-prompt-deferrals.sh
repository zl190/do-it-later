#!/usr/bin/env bash
# user-prompt-deferrals.sh — the RELEVANCE ignition surface (UserPromptSubmit, v0.3).
# Rows with surface `topic:<regex>` come back the moment the user's prompt (or cwd)
# matches their regex AND the row is ripe. Silent otherwise; always exits 0.
set -u
if [ -t 0 ]; then exit 0; fi
payload="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0
text="$(printf '%s' "$payload" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    t = ((d.get("prompt") or "") + " " + (d.get("cwd") or ""))[:3000]
    print(t.replace("\n", " "))
except Exception:
    pass' 2>/dev/null || true)"
[ -n "$text" ] || exit 0

SELF="$(cd "$(dirname "$0")" && pwd)"
SCAN="$SELF/../scripts/scan.sh"
[ -f "$SCAN" ] || exit 0

out="$(bash "$SCAN" match "$text" 2>/dev/null)"
if [ $? -eq 1 ]; then
  printf '[pm-ledger] registry rows relevant to what you are doing right now:\n%s\n' "$out"
fi
exit 0
