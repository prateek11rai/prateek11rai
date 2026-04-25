#!/usr/bin/env bash
# Auto-commit and push vault changes — run by launchd every 15 minutes
set -euo pipefail

LOG_PREFIX="[vault-autosync $(date +%Y-%m-%dT%H:%M:%S)]"

VAULT_PATH="$(cat "$HOME/.claude/obsidian-vault-path" 2>/dev/null || echo "")"
if [ -z "$VAULT_PATH" ] || [ ! -d "$VAULT_PATH/.git" ]; then
  echo "$LOG_PREFIX vault not found at '$VAULT_PATH', skipping"
  exit 0
fi

cd "$VAULT_PATH"

# Pull remote changes first (rebase to keep history clean)
git pull --rebase --quiet 2>/dev/null || true

# Stage all changes
git add -A

# Only commit if there are staged changes
if ! git diff --cached --quiet 2>/dev/null; then
  git commit -m "vault: auto-sync $(date +%Y-%m-%dT%H:%M)"
  git push 2>/dev/null || echo "$LOG_PREFIX push failed (offline?)"
  echo "$LOG_PREFIX committed and pushed"
else
  echo "$LOG_PREFIX no changes"
fi
