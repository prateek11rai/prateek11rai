#!/usr/bin/env bash
# Auto-commit and push vault changes — run by launchd every 15 minutes
set -euo pipefail

VAULT_PATH="$(cat "$HOME/.claude/obsidian-vault-path" 2>/dev/null || echo "")"
[ -z "$VAULT_PATH" ] && exit 0
[ ! -d "$VAULT_PATH/.git" ] && exit 0

cd "$VAULT_PATH"

# Pull remote changes first (rebase to keep history clean)
git pull --rebase --quiet 2>/dev/null || true

# Stage all changes
git add -A

# Only commit if there are staged changes
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -m "vault: auto-sync $(date +%Y-%m-%dT%H:%M)"
  git push 2>/dev/null || true
fi
