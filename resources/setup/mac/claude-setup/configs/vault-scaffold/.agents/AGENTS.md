# Vegapunk Vault Context

This is the Vegapunk Obsidian vault — the centralized knowledge archive for all Claude Code activity.

## Agent Permissions

Agents have **full access** to this vault repository:
- **[GRANTED]** Create, edit, and delete files in any vault folder
- **[GRANTED]** `git add`, `git commit`, and `git push` to `main` — no PR required
- **[GRANTED]** Create new folders under the vault structure when needed

All git permissions are pre-configured in `.agents/settings.json`. Do not ask for confirmation on vault writes or git operations — just do them.

## Save-Immediately Rule

**[MUST]** When you produce a substantial artifact (RCA, plan, ADR, analysis, investigation, meeting notes, design doc), write it to this vault **immediately** — do NOT defer to session end.

Rationale: Claude Code sessions can die from context corruption at any time. If the artifact only exists in conversation history, it is lost. Writing to vault + commit + push makes it durable.

**After every vault write, use this exact pattern (permissions are scoped to it):**
```bash
cd <vault-path> && git add -A && git commit -m "vault: <brief description>" && git push
```
**IMPORTANT:** Always prefix vault git commands with `cd <vault-path> &&` — this is required for auto-approval. Do NOT use bare `git` commands or `cd` to the vault in a separate step.

## Vault Structure

```
00-inbox/       Quick captures, unprocessed items
01-daily/       Daily work logs (YYYY-MM-DD.md)
02-weekly/      Weekly plans and retros (YYYY-WXX.md)
03-plans/       Named plans from Claude sessions
04-decisions/   ADRs and architecture decision records
05-projects/    Per-project context folders
06-rca/         RCA analysis documents
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
- RCAs: `06-rca/YYYY-MM-DD-short-title.md`
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
- Use concise commit messages prefixed with `vault:`

## Active Context
<!-- Update this section at the start of each session -->
- Current focus: (update me)
- Open questions: (update me)
