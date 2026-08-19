# demo-real.tape — UNSCRIPTED: a real ledger file, a real `claude -p` session, the
# model's actual reply (only the model's thinking wait is trimmed via Hide).
Output docs/demo-real.gif
Set FontSize 20
Set Width 1080
Set Height 560
Set Padding 20
Set Theme "Catppuccin Mocha"

Hide
Type `export PM_LEDGER=~/Developer/personal/do-it-later/docs/real-demo/deferrals.tsv; scan() { bash ~/.claude/skills/do-it-later/scripts/scan.sh "$@"; }; clear`
Enter
Show

Type `scan list`
Enter
Sleep 4s
Type `claude -p "Start today's work. Reply in at most 3 short sentences." --model claude-haiku-4-5-20251001`
Enter
Hide
Sleep 90s
Show
Sleep 8s
Type `scan done dark-mode && scan scan`
Enter
Sleep 5s
