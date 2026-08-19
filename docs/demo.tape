# demo.tape — before/after contrast: the delta IS the product.
# Scene 1 (without): a promise dies in silence. Scene 2 (with): same promise comes back.
# Re-record: vhs docs/demo.tape   (throwaway ledger; engine output is real)
Output docs/demo.gif
Set FontSize 21
Set Width 1000
Set Height 480
Set Padding 22
Set TypingSpeed 25ms
Set Theme "Catppuccin Mocha"

Hide
Type `scan() { bash ~/.claude/skills/do-it-later/scripts/scan.sh "$@"; }`
Enter
Type `export PM_LEDGER=$(mktemp -d)/deferrals.tsv`
Enter
Type "clear"
Enter
Show

Type@55ms `# WITHOUT do-it-later`
Enter
Sleep 800ms
Type@55ms `#   you: "the dark-mode toggle? let's do it later."`
Enter
Sleep 1.5s
Type@120ms `#   ...weeks pass...`
Enter
Sleep 1.5s
Type@120ms `#   (nothing comes back. you never even notice.)`
Enter
Sleep 2.8s

Hide
Type "clear"
Enter
Show
Type@55ms `# WITH do-it-later`
Enter
Sleep 800ms
Type@55ms `#   you: "the dark-mode toggle? let's do it later."`
Enter
Sleep 1.2s
Type `scan add dark-mode --due 2026-09-01 --action "add the dark-mode toggle (issue #12)"`
Enter
Sleep 2.2s

Hide
Type `sed -i.bak 's/2026-09-01/2026-08-01/' "$PM_LEDGER"`
Enter
Type "clear"
Enter
Show
Type@55ms `#   ...weeks pass... a NEW session opens:`
Enter
Sleep 1.5s
Type `scan scan`
Enter
Sleep 4s
Type@120ms `#   it came back by itself.`
Enter
Sleep 3s
