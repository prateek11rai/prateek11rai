# Knowledge Vault Context

This is the centralized knowledge archive for all Claude Code activity — Punk Records.

## Agent Permissions

Agents have **full access** to this vault repository:
- **[GRANTED]** Create, edit, and delete files in any vault folder
- **[GRANTED]** `git add`, `git commit`, and `git push` to `main` — no PR required
- **[GRANTED]** Create new folders under the vault structure when needed

All git permissions are pre-configured in `.agents/settings.json`. Do not ask for confirmation on vault writes or git operations — just do them.

## Save-Immediately Rule

**[MUST]** When you produce a substantial artifact (decision, investigation, knowledge note, reference doc), write it to this vault **immediately** — do NOT defer to session end.

Rationale: Claude Code sessions can die from context corruption at any time. If the artifact only exists in conversation history, it is lost.

**Git commits are handled automatically** by a background sync agent that runs every 15 minutes. Just write files — they will be committed and pushed.

## Vault Structure

```
decisions/        ADRs, architecture choices
investigations/   RCAs, debugging journals, analysis, research
knowledge/        Atomic evergreen notes — one concept per file
references/       Architecture docs, checklists, tool references
maps/             Maps of Content — topic indexes linking to related notes
_templates/       Note templates
```

## Conventions

### File Naming
- Decisions: `decisions/YYYY-MM-DD-short-title.md`
- Investigations: `investigations/YYYY-MM-DD-short-title.md`
- Knowledge: `knowledge/descriptive-kebab-name.md` (concept-oriented, not date-oriented)
- References: `references/descriptive-kebab-name.md`
- Maps: `maps/topic-name.md`

### Knowledge Notes (Evergreen)
- **One concept per file** — atomic, reusable, linkable
- Title should be the concept itself (e.g., "impyla-cursor-equals-hs2-session", not "hive debugging notes")
- Include a `## Related` section with wiki-links to related decisions, investigations, and other knowledge
- Use YAML frontmatter with `tags:` for discoverability

### Linking
- Use Obsidian wiki-links: `[[decisions/2026-03-22-hive-005-per-schema-transform]]`
- Maps of Content serve as topic indexes — link decisions, investigations, and knowledge together
- Cross-reference freely between folders

### Tags (YAML frontmatter)
- Topic tags: `[hive, postgres, temporal, atlan-sdk, testing, operational]`
- Type is implicit from the folder — no need for `#type/adr` tags

### Writing to This Vault
- All knowledge artifacts and analysis go here
- Source code stays in project repos — never in this vault
- No secrets, tokens, or credentials
- When in doubt about which folder: knowledge/ for concepts, investigations/ for time-bound research

### Vault Sync
- A background launchd agent auto-commits and pushes every 15 minutes
- No manual git commands needed — just write files and they will be synced
