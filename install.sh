#!/usr/bin/env bash
# install.sh — link the skill into ~/.claude/skills and register the SessionStart hook.
# Idempotent; touches exactly two things and backs up settings.json before editing.
set -u

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"
SKILLS_DIR="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"
# HOOK_CMD stays literal ~/.claude on purpose: it is what goes INTO settings.json.
# CLAUDE_DIR only redirects where THIS script writes (a test hook, mainly).
HOOK_CMD="~/.claude/skills/do-it-later/hooks/session-start-deferrals.sh"

command -v python3 >/dev/null 2>&1 || { echo "install needs python3 (settings.json edit)"; exit 1; }

# 1) symlink the skill (skipped when already installed in place, e.g. via `npx skills add`)
mkdir -p "$SKILLS_DIR"
if [ "$SRC" = "$SKILLS_DIR/do-it-later" ]; then
  echo "in-place at $SRC (no symlink needed)"
else
  ln -sfn "$SRC" "$SKILLS_DIR/do-it-later"
  echo "linked  $SKILLS_DIR/do-it-later -> $SRC"
fi

# 2) register the SessionStart hook (idempotent, with backup)
if [ -f "$SETTINGS" ]; then
  cp "$SETTINGS" "$SETTINGS.bak.$(date +%Y%m%d%H%M%S)"
else
  mkdir -p "$CLAUDE_DIR"
  printf '{}\n' > "$SETTINGS"
fi

SETTINGS="$SETTINGS" HOOK_CMD="$HOOK_CMD" python3 - <<'EOF'
import json, os
path = os.environ['SETTINGS']
cmd = os.environ['HOOK_CMD']
with open(path) as f:
    s = json.load(f)
hooks = s.setdefault('hooks', {})
groups = hooks.setdefault('SessionStart', [])
if not groups:
    groups.append({'matcher': '', 'hooks': []})
entries = groups[0].setdefault('hooks', [])
if any(h.get('command') == cmd for g in groups for h in g.get('hooks', [])):
    print('hook    already registered')
else:
    entries.append({'type': 'command', 'command': cmd})
    with open(path, 'w') as f:
        json.dump(s, f, indent=2, ensure_ascii=False)
        f.write('\n')
    print('hook    registered in settings.json (SessionStart)')
EOF
rc=$?
[ $rc -eq 0 ] || { echo "settings.json edit failed — settings.json was not modified (the step-1 symlink remains; remove with uninstall.sh if unwanted)"; exit $rc; }

echo
echo "done. verify with:  bash $SRC/tests/run.sh"
echo "takes effect from the NEXT Claude Code session (settings are read at session start)."
