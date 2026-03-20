# Vegapunk Vault Context

This is the Vegapunk Obsidian vault — the centralized knowledge archive for all Claude Code activity.

## Vault Structure

```
00-inbox/       Quick captures, unprocessed items
01-daily/       Daily work logs (YYYY-MM-DD.md)
02-weekly/      Weekly plans and retros (YYYY-WXX.md)
03-plans/       Named plans from Claude sessions
04-decisions/   ADRs and architecture decision records
05-projects/    Per-project context folders
06-rca/        RCA analysis documents
07-memory/      Promoted memory dumps from Claude sessions
08-meetings/    Meeting notes
09-archive/     Completed/retired items
_templates/     Obsidian Templater templates
```

## Conventions

### File Naming
- Daily logs: `01-daily/YYYY-MM-DD.md`
- Weekly plans: `02-weekly/YYYY-WXX.md` (ISO week number)
- Plans: `03-plans/descriptive-kebab-name.md` (NEVER use UUIDs or dates as primary name)
- ADRs: `04-decisions/ADR-NNN-short-title.md` (auto-incrementing)
- Meetings: `08-meetings/YYYY-MM-DD-meeting-title.md`

### Linking
- Use Obsidian wiki-links: `[[04-decisions/ADR-001-use-postgres]]`
- Link daily logs to plans, ADRs, and meetings created that day
- Each project folder should have an `overview.md` as entry point

### Tags
- `#status/active`, `#status/completed`, `#status/archived`
- `#type/adr`, `#type/plan`, `#type/rca`, `#type/meeting`
- `#project/project-name` for cross-cutting references

### Writing to This Vault
- All knowledge artifacts, plans, and analysis go here
- Source code stays in project repos — never in this vault
- No secrets, tokens, or credentials
- When creating plans, use descriptive names that reflect the work
- When creating ADRs, scan existing ones to get the next number

### Vault Sync
- After finishing vault writes, commit and push changes in this repo

## Active Context
<!-- Update this section at the start of each session -->
- Current focus: (update me)
- Open questions: (update me)
