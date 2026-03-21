#!/usr/bin/env bash
# Hook: UserPromptSubmit — directs Claude to save artifacts to the vault proactively
# Two modes:
#   1. Knowledge-keyword match → inject save directive
#   2. Always → inject a lightweight general instruction

PROMPT="${CLAUDE_USER_PROMPT:-}"
PROMPT_LOWER="$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')"

VAULT_PATH="$(cat "$HOME/.claude/obsidian-vault-path" 2>/dev/null || echo '')"
[ -z "$VAULT_PATH" ] && exit 0

# Skip purely mechanical commands
MECHANICAL_ONLY='^(git |npm |yarn |pnpm |brew |docker |make |cargo |go build|go run|pip |kubectl |ls |cd |cat |uv run pytest)'
if [[ "$PROMPT_LOWER" =~ $MECHANICAL_ONLY ]]; then
  exit 0
fi

# Keywords that indicate substantial artifact production
ARTIFACT_KEYWORDS="rca|root.cause|analysis|analyze|plan|adr|decision|architecture|design|postmortem|incident|debug.*report|investigate|summary|summarize|document|write.*up|meeting.*notes|retro"

if [[ "$PROMPT_LOWER" =~ ($ARTIFACT_KEYWORDS) ]]; then
  cat <<EOF

<user-prompt-submit-hook>
VAULT SAVE DIRECTIVE — This session involves knowledge work.
When you produce a substantial artifact (RCA, plan, ADR, analysis, meeting notes, investigation report):
1. Write it to the vault IMMEDIATELY after producing it — do NOT wait for session end.
   Vault path: $VAULT_PATH
   Folder map: 03-plans/ 04-decisions/ 06-rca/ 07-memory/ 08-meetings/
2. Use the vault's naming conventions (see $VAULT_PATH/.agents/AGENTS.md).
3. After writing, commit and push to main:
   cd $VAULT_PATH && git add -A && git commit -m "vault: <brief description>" && git push
4. Context corruption can destroy unsaved work. Save early, save often.
</user-prompt-submit-hook>
EOF
  exit 0
fi

# General lightweight reminder for all other prompts (non-mechanical)
# Only fires if conversation seems substantial (prompt > 100 chars)
if [ "${#PROMPT}" -gt 100 ]; then
  cat <<EOF

<user-prompt-submit-hook>
If this task produces reusable knowledge (findings, decisions, patterns), save it to $VAULT_PATH and commit+push. Don't defer to session end.
</user-prompt-submit-hook>
EOF
fi

exit 0
