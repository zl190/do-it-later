#!/usr/bin/env bash
# uninstall.sh — reverse install.sh: drop the hook registration and the skill symlink.
# The ledger (~/.claude/memory/deferrals.tsv) and its usage log are left untouched.
set -u

CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
HOOK_CMD="~/.claude/skills/do-it-later/hooks/session-start-deferrals.sh"

if [ -f "$SETTINGS" ] && command -v python3 >/dev/null 2>&1; then
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
  SETTINGS="$SETTINGS" python3 - <<'EOF'
import json, os
path = os.environ['SETTINGS']
cmds = {
    '~/.claude/skills/do-it-later/hooks/session-start-deferrals.sh',
    '~/.claude/skills/do-it-later/hooks/user-prompt-deferrals.sh',
}
with open(path) as f:
    s = json.load(f)
changed = False
for event in ('SessionStart', 'UserPromptSubmit'):
    for g in s.get('hooks', {}).get(event, []):
        before = len(g.get('hooks', []))
        g['hooks'] = [h for h in g.get('hooks', []) if h.get('command') not in cmds]
        changed = changed or len(g['hooks']) != before
if changed:
    with open(path, 'w') as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
        f.write('\n')
    print('hook    unregistered')
else:
    print('hook    was not registered')
EOF
fi

if [ -L "$CLAUDE_DIR/skills/do-it-later" ]; then
  rm "$CLAUDE_DIR/skills/do-it-later"
  echo "removed $CLAUDE_DIR/skills/do-it-later"
fi
echo "done. ledger left in place: $HOME/.claude/memory/deferrals.tsv"
