# demo-journey.tape — the WHOLE v0.3 journey, real commands: install from GitHub, the
# agent parks promises, a new session gets ONE quiet line, the topic promise returns
# when you touch its subject, close green. Only waits hidden. Re-record: vhs this file.
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

Type `# 1. install (two commands; both hooks register themselves)`
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
Type `# 2. the agent parks its promises (one already due, one topic-scoped)`
Enter
Type `scan add release-notes --due 2026-08-01 --action "ship the v0.3 release notes" --context "CHANGELOG.md"`
Enter
Sleep 2s
Type `scan add dark-mode --check true --surface "topic:ui|login|dark-mode" --action "wire the dark-mode toggle" --context "issue #12"`
Enter
Sleep 2.5s

Type `# 3. a NEW session: the queue is ONE line, not a wall`
Enter
Type `claude -p "Start today's work. If a [pm-ledger] line is in your context, quote it verbatim. 2 sentences max." --model claude-haiku-4-5-20251001`
Enter
Hide
Sleep 100s
Show
Sleep 7s

Type `# 4. ...until you touch the subject of a parked promise:`
Enter
Type `claude -p "Let's restyle the login screen. If a [pm-ledger] relevance block appeared, start with MATCHED <id>, then say how you fold it in. 2 sentences." --model claude-haiku-4-5-20251001`
Enter
Hide
Sleep 100s
Show
Sleep 8s

Type `# 5. close them out`
Enter
Type `scan done dark-mode && scan done release-notes && scan scan`
Enter
Sleep 5s
