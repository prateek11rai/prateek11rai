# Claude Code + Vegapunk Vault Setup

Bootstraps the [Vegapunk](https://github.com/prateek11rai/vegapunk) Obsidian vault and Claude Code configuration on any Mac.

## What It Does

| Step | Action |
|------|--------|
| Prerequisites | Checks for git, Claude Code CLI, Obsidian |
| Vault | Clones the vegapunk repo (or pulls if exists) |
| Scaffold | Creates numbered folder structure + templates |
| CLAUDE.md | Installs user-level preferences to `~/.claude/CLAUDE.md` |
| Status Line | Installs `statusline-command.sh` for Claude Code bottom bar |
| Hooks | Installs vault-write-gate and vault-reminder hooks |
| Plugins | Checks for recommended Obsidian plugins |
| Commit | Commits and pushes the scaffold |

## Usage

```bash
# Default path: ~/github/prateek11rai/vegapunk
bash resources/setup/mac/claude-setup/setup.sh

# Custom vault path
bash resources/setup/mac/claude-setup/setup.sh /path/to/vault
```

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

## Recommended Obsidian Plugins

Install these from Community Plugins in Obsidian:

| Plugin | Purpose |
|--------|---------|
| GitHub Sync | Auto-commit and push to git |
| Templater | Advanced template engine (used by `_templates/`) |
| Dataview | Query notes like a database |
| Calendar | Visual navigation for daily notes |

## Multi-Machine

Run `setup.sh` on each machine. The vault syncs via git. Claude Code memory stays machine-local — promote durable learnings into `07-memory/` or project CLAUDE.md files.
