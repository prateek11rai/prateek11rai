# Vegapunk

> *"The desire to know. That is the motivation of all scientists."*
> — Dr. Vegapunk, One Piece

## Why Vegapunk?

In Eiichiro Oda's *One Piece*, Dr. Vegapunk split his intellect across six satellites, each embodying a different aspect. This vault is the **Punk Records** — the massive library where all accumulated knowledge is stored, accessible to every satellite regardless of where they are.

Just as Punk Records gave each satellite access to the full breadth of Vegapunk's research, this vault gives every machine and every Claude session access to the complete history of what was learned, decided, and investigated.

## What This Vault Is

A centralized, git-synced Obsidian vault that serves as the **persistent knowledge archive** for all Claude Code activity across machines and projects.

**It stores:** decisions, investigations, distilled knowledge, architecture references, and topic maps.

**It does NOT store:** source code, secrets, daily logs, meeting notes, task lists, or calendar events.

## Structure

```
decisions/        ADRs, architecture choices
investigations/   RCAs, debugging journals, analysis, research
knowledge/        Atomic evergreen notes — one concept per file
references/       Architecture docs, checklists, tool references
maps/             Maps of Content — topic indexes linking to related notes
_templates/       Note templates
```

## Why This Structure

**Knowledge-first, not work-tracking.** The original 10-folder structure (inbox, daily, weekly, plans, meetings, archive...) was designed for productivity tracking. None of those folders were ever used. What actually got written were decisions and investigations — knowledge artifacts.

**Zettelkasten-inspired atomic notes.** The `knowledge/` folder holds one-concept-per-file evergreen notes. These are reusable, linkable building blocks — not monolithic documents. A note about "Impyla cursor = HS2 session" can be linked from any investigation or decision that depends on that fact.

**Maps of Content replace deep folder hierarchies.** Instead of nesting files in `projects/hive/decisions/`, a `maps/hive-connector.md` file links to all related decisions, investigations, and knowledge notes. One file can appear in multiple maps without duplication.

**Temporal notes dropped.** Daily logs, weekly plans, and meeting notes are calendar events — they capture a moment, not knowledge. If a meeting produces an insight, that insight becomes a knowledge note or decision. The meeting itself is not worth archiving.

**5 folders, not 10.** Less routing ambiguity for Claude, less noise in the sidebar, clearer purpose for each folder.

## Setup

```bash
# Default (uses preconfigured repo + path)
bash resources/setup/mac/claude-setup/setup.sh

# Custom vault path
bash resources/setup/mac/claude-setup/setup.sh /path/to/vault

# Custom vault path + repo URL
bash resources/setup/mac/claude-setup/setup.sh /path/to/vault https://github.com/you/your-vault.git
```

## Multi-Machine

This vault syncs via git. A background launchd agent auto-commits and pushes every 15 minutes. Claude Code memory (`~/.claude/memory/`) stays machine-local. Durable learnings get **promoted** into this vault's `knowledge/` folder.
