# workbench

My portable Claude Code setup: skills, agents, settings, and the bits that don't
come back on their own after a fresh install.

```sh
git clone https://github.com/krav4enkodm/workbench ~/Projects/workbench
~/Projects/workbench/install.sh --check   # what would change
~/Projects/workbench/install.sh           # roll it out
```

## Day-to-day loop

1. Change things **in the repo**, run `./check.sh`, then `./install.sh`. CI runs
   the same check on every PR.
2. If you tweaked something live (a skill, a setting), `./install.sh --check`
   shows the drift as a diff. Copy what you want to keep into the repo, commit,
   then run `./install.sh` so the machine matches the repo again.

Files are copied, so a live edit under `~/.claude/` is overwritten by the next
install (after a backup to `~/.claude/backups/`). How the installer works and why:
[docs/decisions.md](docs/decisions.md).

## What's here

| Path | Goes to | How |
|---|---|---|
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | copied; personal defaults for every project |
| `claude/skills/*` | `~/.claude/skills/*` | copied |
| `claude/agents/*.md` | `~/.claude/agents/*.md` | copied |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | copied; dir / branch / model / context remaining |
| `claude/settings.json` | `~/.claude/settings.json` | merged; model, permissions, status line, plugins |
| `claude/settings-removed.json` | `~/.claude/settings.json` | keys (dotted paths) deleted after the merge |
| `claude/mcp-servers.json` | `~/.claude.json` → `mcpServers` | merged |

## Skills

| Skill | What it does | Depends on |
|---|---|---|
| `commit` | Commits following the conventions of whatever repo you're in, detected from its history. Title = what changed, body = why. | — |
| `frontend-feature-layers` | Separates a data-backed frontend feature into data / services / presentational components / thin container. | — |
| `plan-work` | Turns an idea or rough ticket into tickets that meet a Definition of Ready, grounded in the codebase. Works with Linear, Jira, GitHub Issues or markdown files. | `readiness-reviewer` agent |
| `work-work` | Implements one ready ticket in its own herdr worktree with a separate Claude worker, checks it with an independent validator, and opens a draft PR. | `plan-work` (`definition-of-ready.md`, `trackers.md`), `ticket-validator` agent, herdr |
| `open-pr` | Opens or rewrites a PR description, following the repo's PR template when it has one; handles `gh stack` stacks. | `gh stack` (optional) |

## Agents

| Agent | Used by | What it does | Depends on |
|---|---|---|---|
| `readiness-reviewer` | `plan-work` | Checks a ticket's claims against the code and returns gaps and questions. | `plan-work` (`review-checklist.md`, `definition-of-ready.md`), Figma plugin |
| `ticket-validator` | `work-work` | Checks a branch against its ticket using only the ticket and the diff; returns PASS or FAIL with a gap list. | Figma plugin |

`plan-work/references/` is shared: renaming or moving a file there breaks the
skills and agents listed above.

## Plan → work workflow

```
/plan-work  →  tickets that meet the Definition of Ready
/work-work  →  per ticket: herdr worktree → worker Claude → validator → draft PR + demo media
you         →  review the draft PR; iterate in the worker pane or via PR comments
```

Fixed assumptions: Claude Code, [herdr](https://herdr.dev) (`work-work` runs inside it),
and GitHub with the `gh` CLI (`gh stack` optional). The tracker, check commands and
demo tooling are discovered per project. For demo videos `work-work` uses the
project's own demo skill, or the `record-video` skill from
agent-video-recorder if `avr` is installed.

If a skill seems missing, check the repo you're in: skills under a project's own
`.claude/skills/` travel with that clone, not with the workbench.
