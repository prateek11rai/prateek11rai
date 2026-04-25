# __USER_NAME__

## Knowledge Vault

All substantial knowledge artifacts produced by Claude Code sessions go to the vault.
Path: read from `~/.claude/obsidian-vault-path`

### Routing Rules

When you produce an artifact matching these types, write it to the vault **immediately** — do not wait for session end:

| Artifact | Folder | Naming |
|----------|--------|--------|
| ADRs / architecture decisions | `decisions/` | `YYYY-MM-DD-short-title.md` |
| RCAs / debugging / analysis | `investigations/` | `YYYY-MM-DD-short-title.md` |
| Atomic concepts / patterns / learnings | `knowledge/` | `descriptive-kebab-name.md` |
| Architecture docs / checklists / tool refs | `references/` | `descriptive-kebab-name.md` |
| Topic indexes (Maps of Content) | `maps/` | `topic-name.md` |

### Rules

- **Write first, talk second** — save the artifact to the vault before continuing the conversation
- **One concept per knowledge note** — atomic, reusable, linkable
- **No git commit needed** — a background agent auto-commits and pushes vault changes every 15 minutes
- Use Obsidian wiki-links (`[[folder/file]]`) for cross-references
- No source code, secrets, or credentials in the vault
- The vault has its own CLAUDE.md with structure and governance rules

## Context

- Engineering preferences are defined per-project in each repo's CLAUDE.md
- Claude auto-memory (`~/.claude/`) stays machine-local; durable learnings get promoted to vault `knowledge/`
