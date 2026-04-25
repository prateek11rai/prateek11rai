# Claude Code + Knowledge Vault Setup

Bootstraps a git-synced Obsidian vault and Claude Code configuration on any Mac.

## What It Does

| Step | Action |
|------|--------|
| Prerequisites | Checks for git, Claude Code CLI, Obsidian |
| Vault | Clones the vault repo (or pulls if exists) |
| Scaffold | Creates knowledge vault folders (decisions, investigations, knowledge, references, maps) + templates |
| CLAUDE.md | Installs vault routing rules to `~/.claude/CLAUDE.md` |
| Status Line | Installs `statusline-command.sh` for Claude Code bottom bar |
| Hooks | Installs vault-write-gate and vault-reminder hooks |
| Auto-sync | Installs launchd agent that commits + pushes every 15 min |
| Plugins | Checks for recommended Obsidian plugins |
| Commit | Commits and pushes the scaffold |

## Usage

```bash
# Default (uses preconfigured defaults)
bash resources/setup/mac/claude-setup/setup.sh

# Custom vault path
bash resources/setup/mac/claude-setup/setup.sh /path/to/vault

# Custom vault path + repo URL (for forking/reuse)
bash resources/setup/mac/claude-setup/setup.sh /path/to/vault https://github.com/you/your-vault.git
```

The script derives your name from `git config user.name` for the Claude config. Both vault path and repo URL are configurable — defaults are in the script header.

## Prerequisites

- macOS
- Git + GitHub access
- [Claude Code](https://claude.com/claude-code) (recommended)
- [Obsidian](https://obsidian.md) (recommended)

## Hooks Installed

| Hook | Trigger | Purpose |
|------|---------|---------|
| `vault-write-gate.sh` | PreToolUse | Blocks `.md` writes outside the vault |
| `vault-reminder.sh` | UserPromptSubmit | Reminds to route knowledge work to vault |

## Auto-Sync

A launchd agent (`com.claude.vault-autosync`) runs every 15 minutes to auto-commit and push any vault changes. This eliminates the need for Claude to run git commands after writing vault files.

Files:
- Script: `~/.claude/vault-autosync.sh`
- Plist: `~/.claude/com.claude.vault-autosync.plist` (symlinked into `~/Library/LaunchAgents/`)

Check status: `launchctl list | grep claude.vault`

## Recommended Obsidian Plugins

Install these from Community Plugins in Obsidian:

| Plugin | Purpose |
|--------|---------|
| Templater | Advanced template engine (used by `_templates/`) |
| Dataview | Query notes like a database |
| Calendar | Visual navigation for daily notes |

## Multi-Machine

Run `setup.sh` on each machine. The vault syncs via git (auto-sync agent handles commit/push). Claude Code memory stays machine-local — promote durable learnings into `knowledge/` in the vault.

## Vault Structure

```
decisions/        ADRs, architecture choices
investigations/   RCAs, debugging journals, analysis
knowledge/        Atomic evergreen notes — one concept per file
references/       Architecture docs, checklists, tool references
maps/             Maps of Content — topic indexes linking related notes
_templates/       Note templates (adr, rca, plan, knowledge, reference, map)
```

## For Other Users

This setup is fully parameterized. To use it with your own vault:

1. Create a new git repo for your vault (GitHub, GitLab, etc.)
2. Run:
   ```bash
   bash setup.sh ~/path/to/your/vault https://github.com/you/your-vault.git
   ```

The script will clone the repo, scaffold the folder structure, install hooks, and configure Claude Code. Your name is derived from `git config user.name` automatically.
