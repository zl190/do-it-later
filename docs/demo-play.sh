#!/usr/bin/env bash
# demo-play.sh — playback script for docs/demo.tape. Renders the two-scene story as a
# Claude Code conversation (staged replay of the live-fire pattern verified in testing;
# the [pm-ledger] block mirrors the hook's real output shape).
set -u

YOU=$'\033[38;5;117m'    # cyan
CLD=$'\033[38;5;216m'    # peach
DIM=$'\033[2m'
RED=$'\033[38;5;203m'
BLD=$'\033[1m'
OFF=$'\033[0m'

tw() { # typewriter print
  local s="$1" i
  for ((i = 0; i < ${#s}; i++)); do printf '%s' "${s:$i:1}"; sleep 0.014; done
  printf '\n'
}
line() { printf '%s\n' "$1"; }

clear
line "${DIM}─ WITHOUT do-it-later ─────────────────────────────${OFF}"
sleep 0.8
printf "${CLD}claude ›${OFF} "; tw "shipped the login fix. i'll wire the dark-mode"
line "         toggle after the refactor lands."
sleep 0.8
printf "${YOU}you    ›${OFF} "; tw "ok"
sleep 1.0
line "${DIM}         (session ends. that promise was just tokens.)${OFF}"
sleep 1.8
line ""
line "${DIM}         ...weeks pass...${OFF}"
sleep 1.6
printf '         '; tw "nothing comes back. you never even notice."
sleep 2.6

clear
line "${DIM}─ WITH do-it-later ────────────────────────────────${OFF}"
sleep 0.8
printf "${CLD}claude ›${OFF} "; tw "shipped the login fix. i'll wire the dark-mode"
line "         toggle after the refactor lands."
sleep 0.6
printf "${CLD}claude ›${OFF} "; tw "parked my promise in the ledger:"
line "         ${BLD}dark-mode${OFF} · due 2026-09-01 · context: issue #12"
sleep 1.0
line "${DIM}         (session ends)${OFF}"
sleep 2.2

clear
line "${DIM}─ weeks later · a NEW session opens ───────────────${OFF}"
sleep 1.2
line "${RED}[pm-ledger]${OFF} a deferred promise is due:"
sleep 0.4
line "  ${RED}${BLD}DUE${OFF}  dark-mode — add the dark-mode toggle (issue #12)"
sleep 1.4
printf "${CLD}claude ›${OFF} "; tw "dark-mode came due, picking it up now."
sleep 3.2
