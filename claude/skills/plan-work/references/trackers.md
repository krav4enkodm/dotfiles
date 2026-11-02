# Trackers

The skill speaks in generic terms: **container** (project / epic / milestone), **ticket**, **blocked-by**, **related**. Map them to whatever is available.

## Order of preference

1. **A repo-specific ticket skill** (e.g. a `create-*-cards` skill in `.claude/skills/`). If one exists, follow its templates, defaults (status, priority, labels) and confirmation rules for the create step. Keep this skill's Definition of Ready content inside its template.
2. **A connected tracker tool** (MCP server or CLI). Discover teams, projects and labels live; never hardcode IDs.
3. **No tracker**: write `docs/plans/<slug>/README.md` (container) and one `NN-<slug>.md` per ticket in the same folder, and ask the user where they'd like them if the repo has no `docs/`.

## Mapping

| Concept | Linear | Jira | GitHub Issues (`gh`) | Markdown files |
|---|---|---|---|---|
| Container | Project (+ milestones) | Epic | Milestone or tracking issue with a task list | `README.md` |
| Ticket | Issue | Story / Task | Issue | `NN-<slug>.md` |
| Blocked-by | `blockedBy` relation | "is blocked by" link | "Blocked by #N" line in body | "Blocked by: NN" line |
| Related | `relatedTo` | "relates to" link | "Related: #N" | "Related: NN" |
| Branch name | Use the issue's generated branch name | Key prefix, e.g. `PROJ-123-…` | `<n>-<slug>` | `<slug>` |

## Rules

- Creating or editing tickets is outward-facing: confirm the plan (titles, order, container) before the first create, unless the user already asked you to create them.
- Assign, prioritise, or schedule only when asked or when the repo's ticket skill says to.
- When editing a ticket later, patch the affected section instead of resending the whole description. Trackers rewrite markdown when they save it (e.g. `-` bullets become `*`, table cells get padded), so copy patch anchors from the ticket as last returned, not from what you sent.
- Put the stack position in each ticket ("Stack 3/6") so the order survives outside the stacking tool.
