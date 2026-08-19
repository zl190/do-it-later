#!/usr/bin/env bash
# tests/run.sh — pm-ledger 变异自检:到期必红/未到期必绿,双向都打。
# 全程 PM_LEDGER 指向临时账本;真账、真 usage log 零污染。
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"
SCAN="$DIR/../scripts/scan.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/pm-ledger-test.XXXXXX")"
export PM_LEDGER="$TMP/deferrals.tsv"
TODAY="$(date +%F)"
pass=0 fail=0

t() { # t <name> <expected-rc> <grep-pattern-or-> <cmd...>
  local name="$1" want_rc="$2" pat="$3"; shift 3
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [ "$rc" -ne "$want_rc" ]; then
    printf '✗ %s — exit %s (want %s)\n%s\n' "$name" "$rc" "$want_rc" "$out"; fail=$((fail+1)); return
  fi
  if [ "$pat" != "-" ] && ! printf '%s' "$out" | grep -Eq "$pat"; then
    printf '✗ %s — output missing /%s/\n%s\n' "$name" "$pat" "$out"; fail=$((fail+1)); return
  fi
  printf '✓ %s\n' "$name"; pass=$((pass+1))
}

tn() { # tn <name> <forbidden-pattern> <cmd...>  (pattern must NOT appear)
  local name="$1" pat="$2"; shift 2
  local out
  out="$("$@" 2>&1)"
  if printf '%s' "$out" | grep -Eq "$pat"; then
    printf '✗ %s — output must NOT contain /%s/\n%s\n' "$name" "$pat" "$out"; fail=$((fail+1)); return
  fi
  printf '✓ %s\n' "$name"; pass=$((pass+1))
}

# ---- 造账 ----
printf 'id\tdue\tcheck\taction\tcontext\tstakes\tsurface\tsource\tstatus\tcreated\n' > "$PM_LEDGER"
add() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$@" >> "$PM_LEDGER"; }
add past-due    2020-01-01 - "act-past"   "ctx-past"   low manual - pending 2020-01-01
add today-due   "$TODAY"   - "act-today"  "ctx-today"  low manual - pending 2020-01-01
add future-due  2099-01-01 - "act-future" "ctx-future" low manual - pending 2020-01-01
add check-hot   - "true"  "act-check-hot"  "ctx" low manual - pending 2020-01-01
add check-cold  - "false" "act-check-cold" "ctx" low manual - pending 2020-01-01

# ---- 变异自检:红侧 ----
t "past due date -> red (exit 1)"          1 'DUE +past-due'  bash "$SCAN" scan
t "due today -> red (boundary includes today)"      1 'DUE +today-due' bash "$SCAN" scan
t "check condition met -> red"             1 'DUE +check-hot' bash "$SCAN" scan
# ---- 变异自检:绿侧(该放的必须没被误伤) ----
tn "future date must not list as DUE"             'DUE +future-due'  bash "$SCAN" scan
tn "unmet check must not list as DUE"     'DUE +check-cold'  bash "$SCAN" scan

# ---- 全绿账本必绿 ----
G="$TMP/green.tsv"
printf 'id\tdue\tcheck\taction\tcontext\tstakes\tsurface\tsource\tstatus\tcreated\n' > "$G"
printf 'only-future\t2099-01-01\t-\ta\tc\tlow\tmanual\t-\tpending\t2020-01-01\n' >> "$G"
t "all-future ledger -> green (exit 0)" 0 'green' env PM_LEDGER="$G" bash "$SCAN" scan

# ---- 边界:主观条件不许入账 ----
t "condition-less row -> INVALID red"  1 'INVALID +no-cond' env PM_LEDGER="$TMP/inv.tsv" bash -c '
  printf "id\tdue\tcheck\taction\tcontext\tstakes\tsurface\tsource\tstatus\tcreated\n" > "$PM_LEDGER"
  printf "no-cond\t-\t-\t等成熟了再说\tctx\tlow\tmanual\t-\tpending\t2020-01-01\n" >> "$PM_LEDGER"
  bash "'"$SCAN"'" scan'
t "add rejects condition-less commitment"     1 'REJECT' bash "$SCAN" add subj-item --action "等有空再弄"

# ---- 边界:捕获漏了 = 机器完全沉默(诚实演示,不是 feature) ----
tn "uncaptured commitment: scan stays silent (honest boundary)" 'ghost-commitment' bash "$SCAN" scan

# ---- add / fire / done / kill 生命周期 ----
t "add valid row"        0 'added lifecycle-x' bash "$SCAN" add lifecycle-x --due 2020-06-06 --action "test act" --context "test ctx" --source "tests/run.sh"
t "add rejects duplicate id"  2 'duplicate'         bash "$SCAN" add lifecycle-x --due 2020-06-06 --action dup
t "fire prints context" 0 'test ctx'          bash "$SCAN" fire lifecycle-x
t "done flips status"       0 '-'                 bash "$SCAN" done lifecycle-x
tn "after done, no longer DUE"  'DUE +lifecycle-x'    bash "$SCAN" scan
t "kill requires a reason"     2 'requires a reason'          bash "$SCAN" kill past-due
t "kill with reason passes"     0 '-'                 bash "$SCAN" kill past-due "test kill reason"
tn "after kill, no longer DUE"  'DUE +past-due'       bash "$SCAN" scan

# ---- 完整性红线(独立复审 blocking finding:畸形行不许静默蒸发) ----
M="$TMP/mal.tsv"
printf 'id\tdue\tcheck\taction\tcontext\tstakes\tsurface\tsource\tstatus\tcreated\n' > "$M"
printf 'nine-cols\t2020-01-01\t-\tact\tctx\tlow\tmanual\t-\tpending\n' >> "$M"          # 9 列
printf 'empty-field\t2020-01-01\t-\tact\t\tlow\tmanual\t-\tpending\t2020-01-01\n' >> "$M" # 空字段
printf 'bad-status\t2020-01-01\t-\tact\tctx\tlow\tmanual\t-\tpendign\t2020-01-01\n' >> "$M" # status 拼错
printf 'bad-due\t2020/01/01\t-\tact\tctx\tlow\tmanual\t-\tpending\t2020-01-01\n' >> "$M"  # 日期格式坏
printf 'well-formed\t2099-01-01\t-\tact\tctx\tlow\tmanual\t-\tpending\t2020-01-01\n' >> "$M"
t "9-column row -> MALFORMED red"      1 'MALFORMED.*nine-cols'   env PM_LEDGER="$M" bash "$SCAN" scan
t "empty-field row -> MALFORMED red"   1 'MALFORMED.*empty-field' env PM_LEDGER="$M" bash "$SCAN" scan
t "bad status row -> MALFORMED"  1 'MALFORMED.*bad-status'  env PM_LEDGER="$M" bash "$SCAN" scan
t "bad due format -> MALFORMED"   1 'MALFORMED.*bad-due'     env PM_LEDGER="$M" bash "$SCAN" scan
t "doctor reds malformed rows too"     1 'MALFORMED'              env PM_LEDGER="$M" bash "$SCAN" doctor
t "list shows malformed rows too"         0 'MALFORMED'              env PM_LEDGER="$M" bash "$SCAN" list
tn "well-formed row not hit as MALFORMED" 'MALFORMED.*well-formed'   env PM_LEDGER="$M" bash "$SCAN" scan

# ---- TSV 撕裂守卫 + id 注入(复审 findings #2/#3) ----
t "kill reason with tab rejected"      2 'tab'          bash "$SCAN" kill check-hot "$(printf 'a\tb')"
t "kill reason with newline rejected"       2 'newline'      bash "$SCAN" kill check-hot "$(printf 'a\nb')"
t "add rejects weird-char id"         2 'bad id'       bash "$SCAN" add 'we[ird' --due 2099-01-01 --action x
t "dotted id: no false-positive duplicate"        0 'added a.b'    bash "$SCAN" add a.b --due 2099-01-01 --action x
t "true duplicate of a.b is caught"          2 'duplicate'    bash "$SCAN" add a.b --due 2099-01-01 --action x
tn "done a.b does not hit axb"      'no such id'     bash "$SCAN" done a.b

# ---- doctor:点火面验活 ----
D="$TMP/doc.tsv"
printf 'id\tdue\tcheck\taction\tcontext\tstakes\tsurface\tsource\tstatus\tcreated\n' > "$D"
printf 'orphan-surf\t2099-01-01\t-\ta\tc\tlow\tno-such-surface\t-\tpending\t2020-01-01\n' >> "$D"
t "doctor catches unknown surface" 1 'unknown-surface +orphan-surf' env PM_LEDGER="$D" bash "$SCAN" doctor

# ---- face:HTML 投影 ----
FH="$TMP/face.html"
t "face 出文件"            0 'face.html' bash "$SCAN" face "$FH"
t "face 含 DUE 行"         0 "chip.>DUE" grep -o "chip'>DUE" "$FH"
printf 'xss-row\t2020-01-01\t-\t<script>alert(1)</script>\tctx\tlow\tmanual\t-\tpending\t2020-01-01\n' >> "$PM_LEDGER"
bash "$SCAN" face "$FH" >/dev/null
t "face 转义 HTML"         0 '&lt;script&gt;' grep -o '&lt;script&gt;' "$FH"
tn "face 不含裸 script 标签" '<script>' cat "$FH"

# ---- usage 计数在写 ----
t "usage log records scan" 0 'cmd=scan' grep 'cmd=scan' "$TMP/deferrals-usage.log"

printf -- '---- %d passed, %d failed ----\n' "$pass" "$fail"
rm -rf "$TMP"
[ "$fail" -eq 0 ]
