#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

VAULT_DEFAULT_PATH="$HOME/github/prateek11rai/vegapunk"
VAULT_DEFAULT_REPO="https://github.com/prateek11rai/vegapunk.git"
CLAUDE_DIR="$HOME/.claude"
USER_NAME="$(git config user.name 2>/dev/null || echo 'User')"

info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }
err()   { printf "\033[1;31m[ERR]\033[0m   %s\n" "$1"; }

backup_if_exists() {
  local target="$1"
  if [ -f "$target" ]; then
    local backup="${target}.backup.${TIMESTAMP}"
    cp "$target" "$backup"
    warn "Backed up $target -> $backup"
  fi
}

# ─── Step 0: Prerequisites ──────────────────────────────────────────────────
info "Checking prerequisites..."

if ! command -v git &>/dev/null; then
  err "git is not installed. Install Xcode Command Line Tools: xcode-select --install"
  exit 1
fi
ok "git available"

if ! command -v claude &>/dev/null; then
  warn "Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code"
else
  ok "Claude Code CLI available"
fi

if [ -d "/Applications/Obsidian.app" ]; then
  ok "Obsidian installed"
else
  warn "Obsidian not found. Install from https://obsidian.md or: brew install --cask obsidian"
fi

# ─── Step 1: Clone or locate vault ──────────────────────────────────────────
VAULT_PATH="${1:-$VAULT_DEFAULT_PATH}"
VAULT_REPO="${2:-$VAULT_DEFAULT_REPO}"
info "Vault path: $VAULT_PATH"
info "Vault repo: $VAULT_REPO"
info "User: $USER_NAME"

if [ -d "$VAULT_PATH/.git" ]; then
  ok "Vault repo already exists at $VAULT_PATH"
  cd "$VAULT_PATH"
  git pull --rebase --quiet 2>/dev/null || warn "Could not pull latest (offline?)"
else
  info "Cloning vault repo..."
  mkdir -p "$(dirname "$VAULT_PATH")"
  git clone "$VAULT_REPO" "$VAULT_PATH"
  ok "Vault cloned to $VAULT_PATH"
fi

# ─── Step 2: Scaffold vault folders ─────────────────────────────────────────
info "Scaffolding vault folder structure..."

SCAFFOLD_DIR="$CONFIGS_DIR/vault-scaffold"
FOLDERS=(
  "decisions"
  "investigations"
  "knowledge"
  "references"
  "maps"
  "_templates"
)

for folder in "${FOLDERS[@]}"; do
  target="$VAULT_PATH/$folder"
  if [ -d "$target" ]; then
    ok "$folder/ exists"
  else
    mkdir -p "$target"
    ok "Created $folder/"
  fi
done

# Copy scaffold files (templates, .gitkeep, etc.) if they exist
if [ -d "$SCAFFOLD_DIR" ]; then
  for folder in "${FOLDERS[@]}"; do
    src="$SCAFFOLD_DIR/$folder"
    dst="$VAULT_PATH/$folder"
    if [ -d "$src" ] && [ "$(ls -A "$src" 2>/dev/null)" ]; then
      cp -rn "$src"/* "$dst"/ 2>/dev/null || true
      ok "Copied scaffold files to $folder/"
    fi
  done
fi

# Copy vault-level files (README.md, .gitignore)
for f in README.md; do
  src="$SCAFFOLD_DIR/$f"
  dst="$VAULT_PATH/$f"
  if [ -f "$src" ]; then
    if [ -f "$dst" ] && [ -s "$dst" ] && [ "$(wc -l < "$dst")" -gt 2 ]; then
      ok "$f already has content, skipping"
    else
      cp "$src" "$dst"
      ok "Copied $f to vault"
    fi
  fi
done

# Set up .agents/AGENTS.md as source of truth
AGENTS_DIR="$VAULT_PATH/.agents"
AGENTS_MD="$AGENTS_DIR/AGENTS.md"

mkdir -p "$AGENTS_DIR"

# Copy AGENTS.md from scaffold if not present or empty
if [ -f "$AGENTS_MD" ] && [ -s "$AGENTS_MD" ] && [ "$(wc -l < "$AGENTS_MD")" -gt 2 ]; then
  ok ".agents/AGENTS.md already has content"
else
  src="$SCAFFOLD_DIR/.agents/AGENTS.md"
  if [ -f "$src" ]; then
    cp "$src" "$AGENTS_MD"
    ok "Created .agents/AGENTS.md"
  fi
fi

# .claude/CLAUDE.md → ../.agents/AGENTS.md symlink (inside vault)
VAULT_CLAUDE_DIR="$VAULT_PATH/.claude"
VAULT_CLAUDE_MD="$VAULT_CLAUDE_DIR/CLAUDE.md"
mkdir -p "$VAULT_CLAUDE_DIR"

if [ -L "$VAULT_CLAUDE_MD" ]; then
  ok ".claude/CLAUDE.md symlink already exists"
elif [ -f "$VAULT_CLAUDE_MD" ]; then
  rm "$VAULT_CLAUDE_MD"
  ln -s ../.agents/AGENTS.md "$VAULT_CLAUDE_MD"
  ok "Replaced .claude/CLAUDE.md with symlink → ../.agents/AGENTS.md"
else
  ln -s ../.agents/AGENTS.md "$VAULT_CLAUDE_MD"
  ok "Created .claude/CLAUDE.md symlink → ../.agents/AGENTS.md"
fi

# .claude/settings.json → ../.agents/settings.json symlink
VAULT_SETTINGS="$VAULT_CLAUDE_DIR/settings.json"
AGENTS_SETTINGS="$AGENTS_DIR/settings.json"

if [ ! -f "$AGENTS_SETTINGS" ]; then
  src="$SCAFFOLD_DIR/.agents/settings.json"
  if [ -f "$src" ]; then
    cp "$src" "$AGENTS_SETTINGS"
    ok "Created .agents/settings.json"
  fi
fi

if [ -L "$VAULT_SETTINGS" ]; then
  ok ".claude/settings.json symlink already exists"
elif [ -f "$VAULT_SETTINGS" ]; then
  rm "$VAULT_SETTINGS"
  ln -s ../.agents/settings.json "$VAULT_SETTINGS"
  ok "Replaced .claude/settings.json with symlink → ../.agents/settings.json"
else
  ln -s ../.agents/settings.json "$VAULT_SETTINGS"
  ok "Created .claude/settings.json symlink → ../.agents/settings.json"
fi

# Remove stale root-level CLAUDE.md if it exists
if [ -f "$VAULT_PATH/CLAUDE.md" ] || [ -L "$VAULT_PATH/CLAUDE.md" ]; then
  rm "$VAULT_PATH/CLAUDE.md"
  ok "Removed root-level CLAUDE.md"
fi

# Vault .gitignore
VAULT_GITIGNORE="$VAULT_PATH/.gitignore"
if [ -f "$CONFIGS_DIR/vault-gitignore" ] && [ ! -f "$VAULT_GITIGNORE" ]; then
  cp "$CONFIGS_DIR/vault-gitignore" "$VAULT_GITIGNORE"
  ok "Created vault .gitignore"
elif [ -f "$VAULT_GITIGNORE" ]; then
  ok "Vault .gitignore already exists"
fi

# ─── Step 3: User-level CLAUDE.md ───────────────────────────────────────────
info "Setting up user-level Claude Code config..."

mkdir -p "$CLAUDE_DIR"

USER_CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
if [ -L "$USER_CLAUDE_MD" ]; then
  rm "$USER_CLAUDE_MD"
elif [ -f "$USER_CLAUDE_MD" ]; then
  backup_if_exists "$USER_CLAUDE_MD"
fi
sed "s|__USER_NAME__|$USER_NAME|g" "$CONFIGS_DIR/user-claude.md" > "$USER_CLAUDE_MD"
ok "Installed ~/.claude/CLAUDE.md (vault config for $USER_NAME)"

# ─── Step 4: Vault path config ──────────────────────────────────────────────
info "Persisting vault path..."

VAULT_PATH_CONFIG="$CLAUDE_DIR/obsidian-vault-path"
echo "$VAULT_PATH" > "$VAULT_PATH_CONFIG"
ok "Vault path saved to $VAULT_PATH_CONFIG"

# ─── Step 5a: Status line script ───────────────────────────────────────────
info "Installing Claude Code status line script..."

STATUSLINE_SRC="$CONFIGS_DIR/statusline-command.sh"
STATUSLINE_DST="$CLAUDE_DIR/statusline-command.sh"

if [ -f "$STATUSLINE_SRC" ]; then
  backup_if_exists "$STATUSLINE_DST"
  cp "$STATUSLINE_SRC" "$STATUSLINE_DST"
  chmod +x "$STATUSLINE_DST"
  ok "Installed statusline-command.sh -> $STATUSLINE_DST"
else
  warn "statusline-command.sh not found in configs"
fi

# ─── Step 5b: Install hooks ─────────────────────────────────────────────────
info "Installing Claude Code hooks..."

HOOKS_DIR="$CLAUDE_DIR/hooks"
mkdir -p "$HOOKS_DIR"

for hook_file in "$CONFIGS_DIR/hooks"/*.sh; do
  [ -f "$hook_file" ] || continue
  hook_name="$(basename "$hook_file")"
  target="$HOOKS_DIR/$hook_name"
  if [ -f "$target" ]; then
    warn "$hook_name already exists, backing up"
    backup_if_exists "$target"
  fi
  cp "$hook_file" "$target"
  chmod +x "$target"
  ok "Installed hook: $hook_name"
done

# Register hooks in settings.json
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

if [ -f "$SETTINGS_FILE" ] && grep -q '"hooks"' "$SETTINGS_FILE" 2>/dev/null; then
  ok "Hooks already registered in settings.json"
else
  info "Registering hooks in settings.json..."

  HOOKS_JSON='{
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/vault-write-gate.sh",
            "timeout": 10,
            "statusMessage": "Checking vault write gate..."
          }
        ]
      }
    ],
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/hooks/vault-reminder.sh",
            "timeout": 5,
            "statusMessage": "Checking vault context..."
          }
        ]
      }
    ]
  }'

  if [ -f "$SETTINGS_FILE" ]; then
    # Merge hooks into existing settings using python (available on macOS)
    python3 -c "
import json, sys
with open('$SETTINGS_FILE', 'r') as f:
    settings = json.load(f)
settings['hooks'] = json.loads('''$HOOKS_JSON''')
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
    ok "Hooks merged into existing settings.json"
  else
    # Create new settings.json with hooks
    python3 -c "
import json
settings = {'hooks': json.loads('''$HOOKS_JSON''')}
with open('$SETTINGS_FILE', 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
    ok "Created settings.json with hooks"
  fi
fi

# ─── Step 5c: Vault path-scoped permissions ────────────────────────────────
info "Adding vault Write/Edit permissions to global settings..."

WRITE_PERM="Write(//${VAULT_PATH}/**)"
EDIT_PERM="Edit(//${VAULT_PATH}/**)"
GIT_PERM="Bash(cd ${VAULT_PATH} && git *)"

python3 -c "
import json

settings_path = '$SETTINGS_FILE'
write_perm = '$WRITE_PERM'
edit_perm = '$EDIT_PERM'
git_perm = '$GIT_PERM'

try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

perms = settings.setdefault('permissions', {})
allow = perms.setdefault('allow', [])

for perm in [write_perm, edit_perm, git_perm]:
    if perm not in allow:
        allow.insert(0, perm)

with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)
    f.write('\n')
"
ok "Vault Write/Edit/Git permissions added to $SETTINGS_FILE"

# ─── Step 5d: Status line in settings.json ─────────────────────────────────
info "Registering status line in settings.json..."

python3 -c "
import json

settings_path = '$SETTINGS_FILE'

try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    settings = {}

if 'statusLine' not in settings:
    settings['statusLine'] = {
        'type': 'command',
        'command': 'bash $CLAUDE_DIR/statusline-command.sh'
    }
    with open(settings_path, 'w') as f:
        json.dump(settings, f, indent=2)
        f.write('\n')
"
ok "Status line registered in settings.json"

# ─── Step 5e: Vault auto-sync agent (launchd) ────────────────────────────────
info "Installing vault auto-sync agent..."

AUTOSYNC_SCRIPT_SRC="$CONFIGS_DIR/vault-autosync.sh"
AUTOSYNC_SCRIPT_DST="$CLAUDE_DIR/vault-autosync.sh"
PLIST_SRC="$CONFIGS_DIR/com.claude.vault-autosync.plist"
PLIST_DST="$CLAUDE_DIR/com.claude.vault-autosync.plist"
PLIST_LINK="$HOME/Library/LaunchAgents/com.claude.vault-autosync.plist"
AGENT_LABEL="com.claude.vault-autosync"

if [ -f "$AUTOSYNC_SCRIPT_SRC" ]; then
  cp "$AUTOSYNC_SCRIPT_SRC" "$AUTOSYNC_SCRIPT_DST"
  chmod +x "$AUTOSYNC_SCRIPT_DST"
  ok "Installed vault-autosync.sh -> $AUTOSYNC_SCRIPT_DST"
else
  warn "vault-autosync.sh not found in configs"
fi

if [ -f "$PLIST_SRC" ]; then
  # Replace placeholder with actual path
  sed "s|__CLAUDE_DIR__|$CLAUDE_DIR|g" "$PLIST_SRC" > "$PLIST_DST"
  ok "Installed plist -> $PLIST_DST"

  # Symlink into LaunchAgents
  mkdir -p "$HOME/Library/LaunchAgents"
  if [ -L "$PLIST_LINK" ] || [ -f "$PLIST_LINK" ]; then
    rm "$PLIST_LINK"
  fi
  ln -s "$PLIST_DST" "$PLIST_LINK"
  ok "Symlinked plist -> $PLIST_LINK"

  # Unload old agent if running, then load new one
  launchctl bootout "gui/$(id -u)/$AGENT_LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST_LINK" 2>/dev/null || true
  ok "Vault auto-sync agent loaded (runs every 15 minutes)"
else
  warn "com.claude.vault-autosync.plist not found in configs"
fi

# ─── Step 6: Obsidian plugin recommendations ────────────────────────────────
info "Checking Obsidian plugins..."

PLUGINS_DIR="$VAULT_PATH/.obsidian/plugins"
RECOMMENDED_PLUGINS=(
  "templater-obsidian:Templater (advanced templates)"
  "dataview:Dataview (query-based views)"
  "calendar:Calendar (daily note navigation)"
)

echo ""
for entry in "${RECOMMENDED_PLUGINS[@]}"; do
  plugin_id="${entry%%:*}"
  plugin_desc="${entry##*:}"
  if [ -d "$PLUGINS_DIR/$plugin_id" ]; then
    ok "Plugin installed: $plugin_desc"
  else
    warn "Plugin missing: $plugin_desc — install from Obsidian Community Plugins"
  fi
done

# ─── Step 7: Initial commit ─────────────────────────────────────────────────
info "Committing scaffold to vault repo..."

cd "$VAULT_PATH"
if [ -n "$(git status --porcelain)" ]; then
  git add -A
  git commit -m "vault: scaffold knowledge vault structure

Folders: decisions, investigations, knowledge, references, maps, templates
Source of truth: .agents/AGENTS.md (CLAUDE.md is symlink)
Includes: README.md, .gitignore, templates"
  git push 2>/dev/null || warn "Could not push (offline?)"
  ok "Scaffold committed and pushed"
else
  ok "No changes to commit"
fi

# ─── Step 8: Summary ────────────────────────────────────────────────────────
echo ""
printf "\033[1;32m✔ Claude Code + vault setup complete!\033[0m\n"
echo ""
echo "What was set up:"
echo "  Vault:       $VAULT_PATH"
echo "  AGENTS.md:   $VAULT_PATH/.agents/AGENTS.md (source of truth)"
echo "  CLAUDE.md:   $USER_CLAUDE_MD (vault routing rules)"
echo "  Status line: $CLAUDE_DIR/statusline-command.sh"
echo "  Vault path:  $VAULT_PATH_CONFIG"
echo "  Hooks:       $HOOKS_DIR/"
echo "  Auto-sync:   $CLAUDE_DIR/vault-autosync.sh (launchd, every 15 min)"
echo ""
echo "Post-setup steps:"
echo "  1. Open the vault in Obsidian (File > Open Vault > $VAULT_PATH)"
echo "  2. Install recommended plugins from Community Plugins"
echo "  3. Verify hooks: claude config list (check hooks section)"
echo "  4. Verify auto-sync: launchctl list | grep claude.vault"
echo ""
echo "Recommended Obsidian plugins to install:"
echo "  - Templater         (advanced template engine)"
echo "  - Dataview          (query notes like a database)"
echo "  - Calendar          (visual daily note navigation)"
echo ""
