#!/usr/bin/env bash
# scan.sh — pm-ledger engine: machine-tripped deferrals (todo_or_die for agents).
# Ledger: TSV, one commitment per row. Conditions are MACHINE-DECIDABLE only:
#   due   = ISO date (fires when today >= due)     — lexicographic compare, no date math
#   check = shell command (fires when exit 0)      — must be instant & read-only
# A row with neither is INVALID and turns the scan red (subjective conditions
# are not admissible — that is the whole point).
# Semantics ported from todo_or_die (due = red, not a reminder) + eslint
# expiring-todo-comments non-date conditions. Date firing is ALWAYS ON — the
# eslint rule ships checkDates:false by default and is therefore dead out of
# the box; we do the opposite on purpose (see pm-ledger/REVERSE.md).
set -u

LEDGER="${PM_LEDGER:-$HOME/.claude/memory/deferrals.tsv}"
USAGE_LOG="$(dirname "$LEDGER")/deferrals-usage.log"
TODAY="$(date +%F)"
HEADER="id	due	check	action	context	stakes	surface	source	status	created"

log_usage() { printf '%s\t%s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$1" >> "$USAGE_LOG"; }

ensure_ledger() {
  if [ ! -f "$LEDGER" ]; then
    mkdir -p "$(dirname "$LEDGER")"
    printf '%s\n' "$HEADER" > "$LEDGER"
  fi
}

# read_rows: emits WELL-FORMED data rows only (exactly 10 non-empty fields).
# Malformed rows are NOT silently dropped — validate_ledger() reds them; the
# two must stay paired (a row invisible here must be visible there).
read_rows() {
  awk -F'\t' 'NR>1 && $1 !~ /^#/ && $1 != "" {
    if (NF != 10) next
    ok = 1; for (i = 1; i <= NF; i++) if ($i == "") ok = 0
    if (ok) print
  }' "$LEDGER"
}

# validate_ledger: integrity red-line. Any data row with wrong column count,
# an empty field (empty ≠ "-"; bash read collapses consecutive tabs, so empty
# fields shift columns and would silently skip the row), a bad status, or a
# bad due format is MALFORMED. Prints findings; returns the count via stdout.
validate_ledger() {
  awk -F'\t' 'NR>1 && $1 !~ /^#/ && $1 != "" {
    bad = ""
    if (NF != 10) bad = "column-count=" NF " (want 10)"
    else {
      for (i = 1; i <= NF; i++) if ($i == "") { bad = "empty field #" i " (use -)"; break }
      if (bad == "" && $9 != "pending" && $9 != "done" && $9 != "killed")
        bad = "bad status \"" $9 "\""
      if (bad == "" && $2 != "-" && $2 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/)
        bad = "bad due \"" $2 "\""
    }
    if (bad != "") { n++; printf "MALFORMED line %d (%s) — %s; row excluded from normal evaluation — fix or delete it\n", NR, $1, bad }
  } END { printf "COUNT=%d\n", n+0 }' "$LEDGER"
}

# fired_p <due> <check> -> 0 if condition met
fired_p() {
  local due="$1" check="$2"
  if [ "$due" != "-" ] && [ ! "$TODAY" \< "$due" ]; then return 0; fi
  if [ "$check" != "-" ] && bash -c "$check" >/dev/null 2>&1; then return 0; fi
  return 1
}

cmd_scan() {
  ensure_ledger
  local fired=0 invalid=0 pending=0 malformed=0
  local vout
  vout="$(validate_ledger)"
  malformed="$(printf '%s\n' "$vout" | awk -F= '/^COUNT=/{print $2}')"
  if [ "$malformed" -gt 0 ]; then printf '%s\n' "$vout" | grep -v '^COUNT='; fi
  local id due check action context stakes surface source status created
  while IFS='	' read -r id due check action context stakes surface source status created; do
    [ "$status" = "pending" ] || continue
    pending=$((pending + 1))
    if [ "$due" = "-" ] && [ "$check" = "-" ]; then
      invalid=$((invalid + 1))
      printf 'INVALID  %s — no machine-decidable condition (due/check both empty); give it one, do it now, or kill it honestly\n' "$id"
    elif fired_p "$due" "$check"; then
      fired=$((fired + 1))
      printf 'DUE      %s — %s\n         context: %s\n         cond: due=%s check=%s | stakes=%s | source=%s\n' \
        "$id" "$action" "$context" "$due" "$check" "$stakes" "$source"
    fi
  done < <(read_rows)
  log_usage "cmd=scan	fired=$fired	invalid=$invalid	malformed=$malformed	pending=$pending"
  if [ $((fired + invalid + malformed)) -gt 0 ]; then
    printf -- '-- pm-ledger: %d due, %d invalid, %d malformed (of %d pending) --\n' "$fired" "$invalid" "$malformed" "$pending"
    return 1
  fi
  printf -- '-- pm-ledger: green (%d pending, none due) --\n' "$pending"
  return 0
}

cmd_list() {
  ensure_ledger
  local id due check action context stakes surface source status created mark
  printf '%-8s %-28s %-12s %-8s %-14s %s\n' STATE ID DUE STAKES SURFACE ACTION
  while IFS='	' read -r id due check action context stakes surface source status created; do
    mark="$status"
    if [ "$status" = "pending" ]; then
      if [ "$due" = "-" ] && [ "$check" = "-" ]; then mark='INVALID'
      elif fired_p "$due" "$check"; then mark='DUE!'
      fi
    fi
    printf '%-8s %-28s %-12s %-8s %-14s %s\n' "$mark" "$id" "$due" "$stakes" "$surface" "$action"
  done < <(read_rows)
  validate_ledger | grep -v '^COUNT=' || true
  log_usage "cmd=list"
}

cmd_fire() {
  ensure_ledger
  local want="$1" found=0
  local id due check action context stakes surface source status created
  while IFS='	' read -r id due check action context stakes surface source status created; do
    [ "$id" = "$want" ] || continue
    found=1
    printf '[pm-ledger fire] %s (status=%s)\n  action:  %s\n  context: %s\n  source:  %s\n  start now; when finished run: scan.sh done %s\n' \
      "$id" "$status" "$action" "$context" "$source" "$id"
  done < <(read_rows)
  log_usage "cmd=fire	id=$want	found=$found"
  if [ "$found" -eq 0 ]; then printf 'no such id: %s\n' "$want" >&2; return 2; fi
}

set_status() { # set_status <id> <new-status> <context-suffix>
  ensure_ledger
  local want="$1" new="$2" suffix="$3" tmp
  case "$suffix" in
    *'	'*) printf 'reason must not contain tabs (would tear the TSV row)\n' >&2; return 2 ;;
  esac
  if [ "$(printf '%s' "$suffix" | wc -l | tr -d ' ')" != "0" ]; then
    printf 'reason must not contain newlines\n' >&2; return 2
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/deferrals.XXXXXX")"
  awk -F'\t' -v OFS='\t' -v id="$want" -v st="$new" -v sfx="$suffix" '
    NR>1 && $1==id { $9=st; if (sfx != "") $5=$5" "sfx; hit=1 }
    { print }
    END { exit hit?0:3 }' "$LEDGER" > "$tmp"
  local rc=$?
  if [ $rc -eq 0 ]; then mv "$tmp" "$LEDGER"; else rm -f "$tmp"; printf 'no such id: %s\n' "$want" >&2; return 2; fi
}

cmd_done() { set_status "$1" done "" && log_usage "cmd=done	id=$1"; }

cmd_kill() {
  local want="$1"; shift
  local reason="${*:-}"
  if [ -z "$reason" ]; then printf 'kill requires a reason: scan.sh kill <id> <reason>\n' >&2; return 2; fi
  set_status "$want" killed "[killed $TODAY: $reason]" && log_usage "cmd=kill	id=$want"
}

cmd_add() {
  # add <id> [--due D] [--check CMD] --action A [--context C] [--stakes S] [--surface F] [--source SRC]
  ensure_ledger
  local id="${1:-}"; shift || true
  local due='-' check='-' action='' context='-' stakes='low' surface='session-start' source='-'
  while [ $# -gt 0 ]; do
    case "$1" in
      --due) due="$2"; shift 2 ;;
      --check) check="$2"; shift 2 ;;
      --action) action="$2"; shift 2 ;;
      --context) context="$2"; shift 2 ;;
      --stakes) stakes="$2"; shift 2 ;;
      --surface) surface="$2"; shift 2 ;;
      --source) source="$2"; shift 2 ;;
      *) printf 'unknown flag: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  if [ -z "$id" ] || [ -z "$action" ]; then printf 'usage: add <id> --action ... [--due|--check ...]\n' >&2; return 2; fi
  if [ "$due" = "-" ] && [ "$check" = "-" ]; then
    printf 'REJECT %s: no machine-decidable condition — give --due/--check, do it now, or kill it honestly\n' "$id" >&2
    return 1
  fi
  if [ "$due" != "-" ] && ! printf '%s' "$due" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    printf 'bad --due (want YYYY-MM-DD): %s\n' "$due" >&2; return 2
  fi
  if ! printf '%s' "$id" | grep -Eq '^[A-Za-z0-9._-]+$'; then
    printf 'bad id (allowed: [A-Za-z0-9._-]): %s\n' "$id" >&2; return 2
  fi
  if awk -F'\t' -v id="$id" 'NR>1 && $1==id{f=1} END{exit f?0:1}' "$LEDGER"; then
    printf 'duplicate id: %s\n' "$id" >&2; return 2
  fi
  case "$id$due$check$action$context$stakes$surface$source" in
    *'	'*) printf 'fields must not contain tabs\n' >&2; return 2 ;;
  esac
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tpending\t%s\n' \
    "$id" "$due" "$check" "$action" "$context" "$stakes" "$surface" "$source" "$TODAY" >> "$LEDGER"
  log_usage "cmd=add	id=$id"
  printf 'added %s (due=%s check=%s surface=%s)\n' "$id" "$due" "$check" "$surface"
}

cmd_doctor() {
  ensure_ledger
  local findings=0
  local vout mal
  vout="$(validate_ledger)"
  mal="$(printf '%s\n' "$vout" | awk -F= '/^COUNT=/{print $2}')"
  if [ "$mal" -gt 0 ]; then
    printf '%s\n' "$vout" | grep -v '^COUNT=' | while IFS= read -r line; do printf 'FINDING %s\n' "$line"; done
    findings=$((findings + mal))
  fi
  local id due check action context stakes surface source status created
  while IFS='	' read -r id due check action context stakes surface source status created; do
    [ "$status" = "pending" ] || continue
    if [ "$due" = "-" ] && [ "$check" = "-" ]; then
      findings=$((findings + 1)); printf 'FINDING invalid-condition %s\n' "$id"
    fi
    case "$surface" in
      session-start)
        if ! grep -q 'session-start-deferrals.sh' "$HOME/.claude/settings.json" 2>/dev/null; then
          findings=$((findings + 1)); printf 'FINDING dead-surface %s — session-start hook not registered in settings.json\n' "$id"
        fi ;;
      cron:*)
        printf 'WARN    unverifiable-surface %s — %s cannot be liveness-checked from bash; verify via your scheduler (does NOT count as green)\n' "$id" "$surface" ;;
      topic:*)
        printf '' | grep -Eiq "${surface#topic:}" 2>/dev/null
        if [ $? -eq 2 ]; then
          findings=$((findings + 1)); printf 'FINDING broken-topic-regex %s -- "%s" is not a valid ERE -- this relevance surface is silently dead\n' "$id" "${surface#topic:}"
        fi
        if ! grep -q 'user-prompt-deferrals.sh' "$HOME/.claude/settings.json" 2>/dev/null; then
          printf 'WARN    topic-surface %s -- user-prompt hook not in settings.json (plugin installs wire it automatically; manual installs: re-run install.sh)\n' "$id"
        fi ;;
      manual) : ;;
      *)
        findings=$((findings + 1)); printf 'FINDING unknown-surface %s — "%s" not in {session-start,topic:<regex>,cron:<name>,manual}\n' "$id" "$surface" ;;
    esac
  done < <(read_rows)
  log_usage "cmd=doctor	findings=$findings"
  if [ "$findings" -gt 0 ]; then printf -- '-- doctor: %d finding(s) --\n' "$findings"; return 1; fi
  printf -- '-- doctor: clean --\n'
}

# signal: the compact SessionStart form (v0.3). The ledger is a REGISTRY, not a todo
# list -- session start gets a one-line count signal (~60 tokens), never the full wall.
# Full context is pulled on demand (list/fire) or at the moment of relevance (match).
# Disposition is only DEMANDED when a high-stakes row tripped.
cmd_signal() {
  ensure_ledger
  local fired=0 invalid=0 malformed=0 hi=''
  malformed="$(validate_ledger | awk -F= '/^COUNT=/{print $2}')"
  local id due check action context stakes surface source status created
  while IFS='	' read -r id due check action context stakes surface source status created; do
    [ "$status" = "pending" ] || continue
    if [ "$due" = "-" ] && [ "$check" = "-" ]; then invalid=$((invalid + 1)); continue; fi
    # topic rows belong to the relevance surface (match); ripeness alone must never
    # make a session start red — that is B1 of round 4 (stay silent until BOTH hold).
    case "$surface" in topic:*) continue ;; esac
    if fired_p "$due" "$check"; then
      fired=$((fired + 1))
      if [ "$stakes" = "high" ]; then hi="$hi $id"; fi
    fi
  done < <(read_rows)
  log_usage "cmd=signal	fired=$fired	invalid=$invalid	malformed=$malformed"
  if [ $((fired + invalid + malformed)) -eq 0 ]; then return 0; fi
  printf '[pm-ledger] %d commitment(s) tripped' "$fired"
  if [ $((invalid + malformed)) -gt 0 ]; then printf ', %d invalid/malformed (run doctor)' "$((invalid + malformed))"; fi
  if [ -n "$hi" ]; then printf ' | HIGH:%s -- needs disposition this session' "$hi"; fi
  printf -- ' -- pull: %s list | fire <id>\n' "$0"
  return 1
}

# match: relevance-triggered ignition (v0.3). Rows with surface `topic:<regex>` stay
# silent until BOTH hold: the row is ripe (due/check) AND the current work (prompt+cwd
# text passed in) matches the regex. Then, and only then, the full context comes back.
cmd_match() {
  ensure_ledger
  local text="$*"
  if [ -z "$text" ]; then return 0; fi
  local shown=0 extra=0
  local id due check action context stakes surface source status created pat
  while IFS='	' read -r id due check action context stakes surface source status created; do
    [ "$status" = "pending" ] || continue
    case "$surface" in topic:*) pat="${surface#topic:}" ;; *) continue ;; esac
    printf '%s' "$text" | grep -Eiq "$pat" 2>/dev/null || continue
    fired_p "$due" "$check" || continue
    if [ "$shown" -ge 3 ]; then extra=$((extra + 1)); continue; fi
    shown=$((shown + 1))
    printf 'RELEVANT %s -- %s
         context: %s
         cond: due=%s check=%s | stakes=%s | source=%s
' \
      "$id" "$action" "$context" "$due" "$check" "$stakes" "$source"
  done < <(read_rows)
  log_usage "cmd=match	shown=$shown	extra=$extra"
  if [ "$shown" -eq 0 ]; then return 0; fi
  if [ "$extra" -gt 0 ]; then printf '(+%d more relevant -- scan.sh list)
' "$extra"; fi
  return 1
}

# face: render the ledger as a self-contained HTML page (a human face for the queue).
# Layout: condition column | action+context+id | a fire button (click = copy command).
# The TSV stays the single source of truth; this is a derived projection, regenerate at
# will. Zero dependencies, light theme with dark auto-variant, one file.
esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

cmd_face() {
  ensure_ledger
  local out="${1:-${TMPDIR:-/tmp}/pm-ledger-face.html}"
  local id due check action context stakes surface source status created
  local rows_due='' rows_pending='' rows_closed='' n_due=0 n_pending=0 n_closed=0
  while IFS='	' read -r id due check action context stakes surface source status created; do
    local when cls badge=''
    if [ "$due" != "-" ]; then when="due $due"
    elif [ "$check" != "-" ]; then when="check: $(esc "${check:0:26}")"
    else when="no condition"
    fi
    case "$status" in
      pending)
        if [ "$due" = "-" ] && [ "$check" = "-" ]; then cls=invalid; badge="<span class='badge inv'>INVALID</span>"
        elif fired_p "$due" "$check"; then cls=due; badge="<span class='badge'>DUE</span>"
        else cls=pending
        fi ;;
      *) cls=closed; badge="<span class='badge off'>$status</span>" ;;
    esac
    local row
    row="<div class='row $cls'><div class='cond'><span class='when'>$when</span>$badge<span class='chip $stakes'>$stakes</span></div><div class='body'><div class='act'>$(esc "$action")</div><div class='ctx'>$(esc "$context") <span class='src'>[$(esc "$source")]</span></div><code class='id'>$(esc "$id")</code></div><button class='fire' onclick=\"copyFire('$(esc "$id")',this)\">&#9889; fire</button></div>"
    case "$cls" in
      due|invalid) rows_due="$rows_due$row"; n_due=$((n_due + 1)) ;;
      pending)     rows_pending="$rows_pending$row"; n_pending=$((n_pending + 1)) ;;
      *)           rows_closed="$rows_closed$row"; n_closed=$((n_closed + 1)) ;;
    esac
  done < <(read_rows)
  {
    printf '<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>pm-ledger</title><style>'
    printf ':root{--bg:#f7f5f1;--card:#fff;--bd:#e6e2d9;--tx:#2f2c26;--dim:#8b867b;--mono:#6f6a60;--red:#b03e36;--amb:#9a7b00;--grn:#3d7a45}'
    printf '@media (prefers-color-scheme:dark){:root{--bg:#1e1e2e;--card:#181825;--bd:#313244;--tx:#cdd6f4;--dim:#7f849c;--mono:#a6adc8;--red:#f38ba8;--amb:#f9e2af;--grn:#a6e3a1}}'
    printf 'body{background:var(--bg);color:var(--tx);font:16px/1.5 -apple-system,system-ui,sans-serif;max-width:920px;margin:34px auto;padding:0 20px}'
    printf 'h1{font-size:22px;margin:0 0 16px}h1 small{color:var(--dim);font-weight:400;font-size:15px;margin-left:12px}'
    printf '.row{display:flex;gap:18px;align-items:flex-start;background:var(--card);border:1px solid var(--bd);border-radius:14px;padding:16px 18px;margin:12px 0}'
    printf '.cond{flex:0 0 138px;display:flex;flex-direction:column;gap:7px;align-items:flex-start}'
    printf '.when{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:14.5px;font-weight:600}'
    printf '.due .when{color:var(--red)}.invalid .when{color:var(--amb)}'
    printf '.badge{font-size:10.5px;font-weight:800;color:#fff;background:var(--red);border-radius:5px;padding:1px 7px;letter-spacing:.5px}'
    printf '.badge.inv{background:var(--amb)}.badge.off{background:var(--dim)}'
    printf '.chip{font-size:12px;border:1.5px solid var(--bd);color:var(--dim);border-radius:99px;padding:1px 11px}'
    printf '.chip.high{color:var(--red);border-color:var(--red)}'
    printf '.body{flex:1;min-width:0}.act{font-size:16.5px;font-weight:600;line-height:1.4}'
    printf '.ctx{color:var(--dim);font-size:13.5px;margin-top:4px}.src{opacity:.75}'
    printf '.id{display:block;font-size:12px;color:var(--mono);margin-top:5px;font-family:ui-monospace,SFMono-Regular,Menlo,monospace}'
    printf '.fire{flex:0 0 auto;align-self:center;font:600 14px ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--tx);background:var(--card);border:1.5px solid var(--bd);border-radius:11px;padding:9px 16px;cursor:pointer}'
    printf '.fire:hover{border-color:var(--dim)}'
    printf '.closed{opacity:.45}footer{color:var(--dim);font-size:12.5px;margin-top:20px}</style>'
    printf '<h1>pm-ledger <small>%s due/invalid &#183; %s pending &#183; %s closed &#183; %s</small></h1>' "$n_due" "$n_pending" "$n_closed" "$TODAY"
    printf '%s%s%s' "$rows_due" "$rows_pending" "$rows_closed"
    printf '<footer>projection of %s &#8212; the TSV is the truth; regenerate with <code>scan.sh face</code>. &#9889; = click to copy the fire command.</footer>' "$(esc "$LEDGER")"
    printf '<script>function copyFire(id,el){var c="bash ~/.claude/skills/do-it-later/scripts/scan.sh fire "+id;if(navigator.clipboard){navigator.clipboard.writeText(c)}el.textContent="copied";setTimeout(function(){el.innerHTML="&#9889; fire"},900)}</script>'
  } > "$out"
  log_usage "cmd=face	due=$n_due	pending=$n_pending"
  printf '%s\n' "$out"
}

case "${1:-scan}" in
  scan) cmd_scan ;;
  signal) cmd_signal ;;
  match) shift; cmd_match "$@" ;;
  list) cmd_list ;;
  face) shift; cmd_face "${1:-}" ;;
  fire) shift; cmd_fire "${1:?usage: fire <id>}" ;;
  done) shift; cmd_done "${1:?usage: done <id>}" ;;
  kill) shift; cmd_kill "$@" ;;
  add) shift; cmd_add "$@" ;;
  doctor) cmd_doctor ;;
  *) printf 'usage: scan.sh {scan|signal|match <text>|list|face [out.html]|fire <id>|done <id>|kill <id> <reason>|add <id> ...|doctor}\n' >&2; exit 2 ;;
esac
