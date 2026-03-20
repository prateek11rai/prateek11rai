#!/usr/bin/env bash
# Hook: PreToolUse — blocks .md file writes outside the vault
# Ensures all documentation routes through the Vegapunk vault

VAULT_PATH_FILE="$HOME/.claude/obsidian-vault-path"

# Only gate Write and Edit tools
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

# Get the file path from the tool input
FILE_PATH="${CLAUDE_TOOL_INPUT_FILE_PATH:-}"

# Skip if not a markdown file
if [[ "$FILE_PATH" != *.md ]]; then
  exit 0
fi

# Allow Claude's own config files
if [[ "$FILE_PATH" == *"/.claude/"* ]]; then
  exit 0
fi

# Allow CLAUDE.md files anywhere (project-level config)
if [[ "$(basename "$FILE_PATH")" == "CLAUDE.md" ]]; then
  exit 0
fi

# Allow files inside the vault
if [ -f "$VAULT_PATH_FILE" ]; then
  VAULT_PATH="$(cat "$VAULT_PATH_FILE")"
  if [[ "$FILE_PATH" == "$VAULT_PATH"* ]]; then
    exit 0
  fi
fi

# Block all other .md writes — remind to use the vault
echo "BLOCK: Markdown files should be written to the Vegapunk vault."
echo "Vault path: $(cat "$VAULT_PATH_FILE" 2>/dev/null || echo 'not configured')"
echo "Route this content to the appropriate vault folder instead."
exit 2
