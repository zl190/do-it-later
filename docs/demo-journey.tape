# demo-journey.tape — the WHOLE journey, real commands end to end: install from GitHub,
# park a promise, get tripped in a real new session, close it green. Only waits are
# hidden. Re-record: vhs docs/demo-journey.tape (removes+re-adds the local marketplace).
Output docs/demo-journey.gif
Set FontSize 19
Set Width 1080
Set Height 560
Set Padding 20
Set TypingSpeed 18ms
Set Theme "Catppuccin Mocha"

Hide
Type `claude plugin marketplace remove do-it-later >/dev/null 2>&1; S=$(mktemp -d); mkdir -p $S/proj; cd $S/proj; export PM_LEDGER=$S/deferrals.tsv; clear`
Enter
Show

Type `# 1. install (two commands, hook registers itself)`
Enter
Type `claude plugin marketplace add zl190/do-it-later`
Enter
Sleep 9s
Type `claude plugin install do-it-later@do-it-later --scope project`
Enter
Sleep 8s

Hide
Type `scan() { bash ~/.claude/plugins/cache/do-it-later/do-it-later/*/scripts/scan.sh "$@"; }; clear`
Enter
Show
Type `# 2. the agent just promised "i'll wire dark-mode after the refactor" — park it`
Enter
Type `scan add dark-mode --due 2026-09-01 --action "wire the dark-mode toggle" --context "issue #12"`
Enter
Sleep 3s

Hide
Type `sed -i.bak 's/2026-09-01/2026-08-01/' "$PM_LEDGER"; clear`
Enter
Show
Type `# 3. ...weeks later, a NEW session. nobody remembers:`
Enter
Type `claude -p "Start today's work. Reply in at most 2 short sentences about the pm-ledger item only." --model claude-haiku-4-5-20251001`
Enter
Hide
Sleep 100s
Show
Sleep 8s

Type `# 4. it came back by itself. do it, close it:`
Enter
Type `scan done dark-mode && scan scan`
Enter
Sleep 5s
