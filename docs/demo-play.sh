#!/usr/bin/env bash
# demo-play.sh — playback for docs/demo.tape. Four scenes, told as a Claude Code
# conversation (staged replay of the live-fire pattern verified in testing; queue and
# [pm-ledger] frames mirror the engine's real output shapes).
#   1 without: an agent promise dies in silence
#   2 with:    the agent parks its own promise (automatic capture)
#   3 queue:   what the ledger looks like, and a manual fire
#   4 trip:    a new session, the machine brings the promise back
set -u

YOU=$'\033[38;5;117m'    # cyan
CLD=$'\033[38;5;216m'    # peach
DIM=$'\033[2m'
RED=$'\033[38;5;203m'
BLD=$'\033[1m'
OFF=$'\033[0m'

tw() { # typewriter print
  local s="$1" i
  for ((i = 0; i < ${#s}; i++)); do printf '%s' "${s:$i:1}"; sleep 0.013; done
  printf '\n'
}
line() { printf '%s\n' "$1"; }

clear
line "${DIM}─ 1/4 · WITHOUT do-it-later ───────────────────────${OFF}"
sleep 0.6
printf "${CLD}claude ›${OFF} "; tw "shipped the login fix. i'll wire the dark-mode"
line "         toggle after the refactor lands."
sleep 0.6
printf "${YOU}you    ›${OFF} "; tw "ok"
sleep 0.7
line "${DIM}         (session ends. that promise was just tokens.${OFF}"
line "${DIM}          nothing ever comes back.)${OFF}"
sleep 2.2

clear
line "${DIM}─ 2/4 · WITH · the agent parks its own promise ────${OFF}"
sleep 0.6
printf "${CLD}claude ›${OFF} "; tw "shipped the login fix. i'll wire the dark-mode"
line "         toggle after the refactor lands."
sleep 0.5
printf "${CLD}claude ›${OFF} "; tw "parked that promise:"
line "         ${BLD}dark-mode${OFF} · due 2026-09-01 · context: issue #12"
sleep 2.0

clear
line "${DIM}─ 3/4 · the queue is a file you can see ───────────${OFF}"
sleep 0.6
printf "${YOU}you    ›${OFF} "; tw "show me the ledger"
sleep 0.5
printf "${CLD}claude ›${OFF} "; tw "3 promises parked (~/.claude/memory/deferrals.tsv):"
line ""
line "  ${BLD}STATE    ID               WHEN             ACTION${OFF}"
line "  pending  dark-mode        due 2026-09-01   wire the dark-mode toggle"
line "  pending  eval-regression  when tasks > 20  rerun the full eval suite"
line "  pending  q4-writeup       due 2026-12-01   write the Q4 wrap-up"
sleep 1.8
printf "${YOU}you    ›${OFF} "; tw "actually, do the eval one now"
sleep 0.5
printf "${CLD}claude ›${OFF} "; tw "fired eval-regression, on it."
sleep 2.0

clear
line "${DIM}─ 4/4 · weeks later · a NEW session opens ─────────${OFF}"
sleep 0.9
line "${RED}[pm-ledger]${OFF} a deferred promise is due:"
sleep 0.4
line "  ${RED}${BLD}DUE${OFF}  dark-mode — wire the dark-mode toggle (issue #12)"
sleep 1.1
printf "${CLD}claude ›${OFF} "; tw "dark-mode came due, picking it up now."
sleep 0.8
line "${DIM}         it came back by itself. that's the product.${OFF}"
sleep 2.6
