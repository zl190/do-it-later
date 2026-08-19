# demo.tape — the story as it actually happens: a Claude Code conversation.
# Scene 1 (without): the promise dies in silence. Scenes 2-3 (with): you say the same
# sentence; the skill parks it; a NEW session gets tripped and the agent picks it up.
# Playback lives in docs/demo-play.sh (staged replay of the verified live-fire pattern).
# Re-record: vhs docs/demo.tape
Output docs/demo.gif
Set FontSize 21
Set Width 1000
Set Height 480
Set Padding 22
Set Theme "Catppuccin Mocha"

Hide
Type `bash docs/demo-play.sh; sleep 60`
Enter
Sleep 400ms
Show
Sleep 27s
