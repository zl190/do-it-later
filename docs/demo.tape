# demo.tape — deterministic README demo. Re-record: vhs docs/demo.tape
# Uses a throwaway ledger (PM_LEDGER=mktemp); never touches a real one.
Output docs/demo.gif
Set FontSize 15
Set Width 1000
Set Height 620
Set Padding 18
Set TypingSpeed 30ms
Set Theme "Catppuccin Mocha"

Hide
Type `scan() { bash ~/.claude/skills/do-it-later/scripts/scan.sh "$@"; }`
Enter
Type `export PM_LEDGER=$(mktemp -d)/deferrals.tsv`
Enter
Type `scan add fix-flaky-timer --due 2026-08-15 --action "revisit the flaky timer test" --context "tests/timer.spec.ts; repro: run 20x; suspect: fake-clock drift" --source "PR #88 review: 'we will fix it later'"`
Enter
Type `scan add q4-writeup --due 2026-12-01 --action "write the Q4 wrap-up" --context "material in blog/drafts/"`
Enter
Type "clear"
Enter
Show

Type `# "later" without a machine-decidable condition? rejected:`
Enter
Type `scan add someday-refactor --action "refactor once the architecture matures"`
Enter
Sleep 2.8s

Type `# what's due? (the SessionStart hook runs this every session)`
Enter
Type `scan scan`
Enter
Sleep 4s

Type `# trip it -> work it -> close it`
Enter
Type `scan fire fix-flaky-timer`
Enter
Sleep 3.2s

Type `scan done fix-flaky-timer && scan scan`
Enter
Sleep 3.5s
