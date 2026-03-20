# Vegapunk

> *"The desire to know. That is the motivation of all scientists."*
> — Dr. Vegapunk, One Piece

## Why Vegapunk?

In Eiichiro Oda's *One Piece*, Dr. Vegapunk is the world's greatest scientist — a mind so vast that it could not be contained in a single body. He split himself into six satellites, each embodying a different aspect of his intellect:

| Satellite | Aspect | Parallel Here |
|-----------|--------|---------------|
| **Shaka** | Good / Wisdom | Architecture decisions, plans |
| **Lilith** | Evil / Pragmatism | Risk analysis, writeoffs |
| **Edison** | Thinking / Ideas | Daily captures, inbox |
| **Pythagoras** | Knowledge / Logic | Memory, patterns, debugging |
| **Atlas** | Violence / Action | Execution logs, meeting notes |
| **York** | Greed / Desire | Goals, weekly plans |

This vault is the **Punk Records** — the massive library where Vegapunk stored all of his accumulated knowledge, accessible to every satellite. Just as Punk Records gave each satellite access to the full breadth of Vegapunk's research regardless of where they were, this vault gives every machine and every Claude session access to the complete history of work.

## What This Vault Is

A centralized, git-synced Obsidian vault that serves as the **persistent memory and work archive** for all Claude Code activity across machines and projects.

**It stores:**
- Daily work logs and weekly plans
- Architecture Decision Records (ADRs)
- Named plans from Claude sessions
- RCA analysis documents
- Promoted memory dumps (patterns, debugging insights)
- Meeting notes and project context

**It does NOT store:**
- Source code (that stays in project repos)
- Secrets, tokens, or credentials
- Machine-specific ephemeral state
- Personal/human-written artifacts (those live in OM)

## Structure

```
00-inbox/       Unprocessed captures (Edison's workshop)
01-daily/       Daily work logs (YYYY-MM-DD.md)
02-weekly/      Weekly plans and retros (YYYY-WXX.md)
03-plans/       Named plans from Claude sessions
04-decisions/   ADRs and architecture records
05-projects/    Per-project folders
06-rca/        RCA analysis documents
07-memory/      Promoted memory dumps
08-meetings/    Meeting notes
09-archive/     Completed/retired items
_templates/     Obsidian Templater templates
```

## Setup

```bash
# From the prateek11rai repo
bash resources/setup/mac/claude-setup/setup.sh
```

Or see the [setup README](../prateek11rai/resources/setup/mac/claude-setup/README.md).

## Multi-Machine

This vault syncs via git. The rule is simple:
1. Close Obsidian on Machine A (triggers commit + push)
2. Open Obsidian on Machine B (triggers pull)
3. Work. Auto-commits handle the rest.

Claude Code memory (`~/.claude/memory/`) stays machine-local. Durable learnings get **promoted** into this vault's `07-memory/` folder or into project CLAUDE.md files.
