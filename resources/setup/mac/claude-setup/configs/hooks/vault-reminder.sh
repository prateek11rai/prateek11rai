#!/usr/bin/env bash
# Hook: UserPromptSubmit — reminds to route knowledge work to the vault
# Triggers on prompts that contain knowledge/documentation keywords

PROMPT="${CLAUDE_USER_PROMPT:-}"
PROMPT_LOWER="$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')"

# Skip purely mechanical commands
MECHANICAL_ONLY='^(git |npm |yarn |pnpm |brew |docker |make |cargo |go build|go run|pip |kubectl )'
if [[ "$PROMPT_LOWER" =~ $MECHANICAL_ONLY ]]; then
  exit 0
fi

# Knowledge keywords that should trigger a vault reminder
KNOWLEDGE_WORDS="write|note|store|document|plan|adr|decision|architecture|analyze|analysis|rca|risk|meeting|daily|weekly|log|journal|summarize|summary|explain|memory|remember|record"

if [[ "$PROMPT_LOWER" =~ ($KNOWLEDGE_WORDS) ]]; then
  VAULT_PATH="$(cat "$HOME/.claude/obsidian-vault-path" 2>/dev/null || echo '')"
  if [ -n "$VAULT_PATH" ]; then
    echo ""
    echo "--- Vegapunk Vault Reminder ---"
    echo "This looks like knowledge work. Route artifacts to: $VAULT_PATH"
    echo "Structure: 01-daily/ 02-weekly/ 03-plans/ 04-decisions/ 06-rca/ 07-memory/"
    echo "Use descriptive names, wiki-links, and appropriate tags."
    echo "-------------------------------"
  fi
fi

exit 0
