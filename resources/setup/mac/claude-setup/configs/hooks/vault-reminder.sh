#!/usr/bin/env bash
# Hook: UserPromptSubmit — directs Claude to save artifacts to the vault proactively
# Two modes:
#   1. Knowledge-keyword match → inject save directive with folder map
#   2. Substantial prompt (>100 chars) → inject lightweight reminder

PROMPT="${CLAUDE_USER_PROMPT:-}"
PROMPT_LOWER="$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')"

VAULT_PATH="$(cat "$HOME/.claude/obsidian-vault-path" 2>/dev/null || echo '')"
[ -z "$VAULT_PATH" ] && exit 0

# Skip purely mechanical commands
MECHANICAL_ONLY='^(git |npm |yarn |pnpm |brew |docker |make |cargo |go build|go run|pip |kubectl |ls |cd |cat |uv run|rm |mv |cp |chmod |/)'
if [[ "$PROMPT_LOWER" =~ $MECHANICAL_ONLY ]]; then
  exit 0
fi

# Keywords that indicate substantial artifact production
ARTIFACT_KEYWORDS="rca|root.cause|analysis|analyze|plan|adr|decision|architecture|design|postmortem|incident|debug.*report|investigate|investigation|summary|summarize|document|write.*up|meeting.*notes|retro|findings|research|compare|writeoff|benchmark|trd|runbook|playbook|context|learning|pattern|deep.?dive|break.?down|explain.*why|risk.*analysis"

if [[ "$PROMPT_LOWER" =~ ($ARTIFACT_KEYWORDS) ]]; then
  cat <<EOF

<user-prompt-submit-hook>
VAULT SAVE DIRECTIVE — This session involves knowledge work.
When you produce a substantial artifact (RCA, plan, ADR, analysis, meeting notes, investigation report):
1. Write it to the vault IMMEDIATELY — do NOT wait for session end.
   Vault path: $VAULT_PATH
   Folder map: decisions/ | investigations/ | knowledge/ | references/ | maps/
2. Use the vault's naming conventions (see $VAULT_PATH/.agents/AGENTS.md).
3. No git commit needed — a background agent auto-commits and pushes every 15 minutes.
4. Context corruption can destroy unsaved work. Save early, save often.
</user-prompt-submit-hook>
EOF
  exit 0
fi

# General lightweight reminder for non-mechanical prompts > 100 chars
if [ "${#PROMPT}" -gt 100 ]; then
  cat <<EOF

<user-prompt-submit-hook>
If this task produces reusable knowledge (findings, decisions, patterns), save it to $VAULT_PATH. No git commit needed — auto-sync handles it.
</user-prompt-submit-hook>
EOF
fi

exit 0
