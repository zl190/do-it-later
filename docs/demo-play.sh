#!/usr/bin/env bash
# demo-play.sh — playback for docs/demo.tape (staged storyboard; engine lines mirror
# the real v0.3 output shapes exactly).
#   1 without: an agent promise dies in silence
#   2 with:    the agent parks its own promise (a topic row)
#   3 signal:  a new session gets ONE quiet line, not a wall
#   4 match:   the promise comes back the moment you touch its subject
set -u

YOU=$'\033[38;5;117m'
CLD=$'\033[38;5;216m'
DIM=$'\033[2m'
RED=$'\033[38;5;203m'
BLD=$'\033[1m'
OFF=$'\033[0m'

tw() {
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
printf "${CLD}claude ›${OFF} "; tw "parked that promise in the registry:"
line "         ${BLD}dark-mode${OFF} · due 2026-09-01 · surface topic:ui|dark-mode|login"
sleep 2.2

clear
line "${DIM}─ 3/4 · a NEW session. the queue stays out of the way ─${OFF}"
sleep 0.9
line "${RED}[pm-ledger]${OFF} 1 commitment(s) tripped -- pull: scan.sh list | fire <id>"
sleep 1.0
line "${DIM}         that's the whole session-start footprint: one line.${OFF}"
line "${DIM}         (a release-notes row came due; dark-mode stays quiet --${OFF}"
line "${DIM}          its moment hasn't come.)${OFF}"
sleep 3.0

clear
line "${DIM}─ 4/4 · ...until you touch its subject ────────────${OFF}"
sleep 0.8
printf "${YOU}you    ›${OFF} "; tw "let's restyle the login screen today"
sleep 0.8
line "${RED}[pm-ledger]${OFF} registry rows relevant to what you are doing right now:"
line "  ${RED}${BLD}RELEVANT${OFF} dark-mode -- wire the dark-mode toggle"
line "           context: issue #12; tokens live in shared/COLORS.md"
sleep 1.2
printf "${CLD}claude ›${OFF} "; tw "the dark-mode promise belongs to exactly this area."
printf "         "; tw "folding it into the restyle."
sleep 0.9
line "${DIM}         it came back the moment it mattered. that's the product.${OFF}"
sleep 2.8
