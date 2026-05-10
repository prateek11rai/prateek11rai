# prateek11rai

Personal bootstrapper for Mac environments, terminal configurations, and AI agent workflows.

## Environment Setup
- **Mac Terminal:** `bash resources/setup/mac/terminal-setup/setup.sh` (no args, idempotent — Starship, Tmux, Neofetch, FiraCode)
- **Claude + Vault:** `bash resources/setup/mac/claude-setup/setup.sh [vault_path] [vault_repo]`
- **Vault Path:** Stored in `~/.claude/obsidian-vault-path` (usually `~/github/prateek11rai/vegapunk`)

## Knowledge Vault (Vegapunk)
Route durable learnings, ADRs, and RCAs to the vault. Use its templates for structured entries.
- `decisions/`: ADRs and architecture choices
- `investigations/`: RCAs and debugging journals
- `knowledge/`: Atomic evergreen notes
- `references/`: Docs, checklists, and tool references
- `maps/`: Topic indexes (MOCs)

## Rules
- **No Co-authors:** Do not add co-author lines when committing to this repo.
- **Vault writes:** Put knowledge-heavy output (ADRs, RCAs, architecture notes) into the vault, not in local files. Use vault templates.
- **Syncing:** The vault uses a `launchd` agent (`com.claude.vault-autosync`) for auto-commits every 15 minutes.
