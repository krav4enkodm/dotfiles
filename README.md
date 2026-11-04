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
| `claude/rules/*.md` | `~/.claude/rules/*.md` | copied; load when Claude touches matching files |
| `claude/hooks/*.sh` | `~/.claude/hooks/*.sh` | copied, one file at a time; herdr's own hook there is left alone |
| `claude/agents/*.md` | `~/.claude/agents/*.md` | copied |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | copied; dir / branch / model / context remaining |
| `claude/settings.json` | `~/.claude/settings.json` | merged; model, permissions and deny rules, hooks, status line, plugins |
| `claude/settings-removed.json` | `~/.claude/settings.json` | keys (dotted paths) deleted after the merge |
| `claude/mcp-servers.json` | `~/.claude.json` → `mcpServers` | merged |

## Skills

| Skill | What it does | Depends on |
|---|---|---|
| `commit` | Commits following the conventions of whatever repo you're in, detected from its history. Title = what changed, body = why. | — |
| `plan-work` | Turns an idea or rough ticket into tickets that meet a Definition of Ready, grounded in the codebase. Works with Linear, Jira, GitHub Issues or markdown files. | `readiness-reviewer` agent |
| `work-work` | Runs only as `/work-work`. Implements one ready ticket in its own herdr worktree with a separate Claude worker, checks it with an independent validator, and opens a draft PR. | `plan-work` (`definition-of-ready.md`, `trackers.md`, `design.md`), `ticket-validator` agent, herdr |
| `open-pr` | Opens or rewrites a PR description, following the repo's PR template when it has one; attaches screenshots and demo videos with `gh --attach`; handles `gh stack` stacks. | `gh stack` (optional) |

## Agents

| Agent | Used by | What it does | Depends on |
|---|---|---|---|
| `readiness-reviewer` | `plan-work` | Checks a ticket's claims against the code and returns gaps and questions. | `plan-work` (`review-checklist.md`, `definition-of-ready.md`, `design.md`), `bash-guard.sh` hook, Figma plugin |
| `ticket-validator` | `work-work` | Checks a branch against its ticket using only the ticket, the diff and the running app; returns PASS or FAIL with a gap list. | `plan-work` (`design.md`), `bash-guard.sh` hook, Figma plugin, `chrome-devtools` MCP (UI tickets) |

## Rules

| Rule | Loads for | What it says |
|---|---|---|
| `frontend-feature-layers` | `*.tsx`, `*.jsx` | Lay out a data-backed React feature as data / services / presentational components / thin container. |

## Guardrails

Things that must never happen are enforced, not just written down. They match
the usual form of a command, so treat them as guardrails, not a sandbox.

- **Deny rules** in `settings.json`: no `gh pr merge`, `gh pr ready`,
  `gh stack merge`, `gh stack unstack`, or `gh stack submit --open`. Run those
  yourself.
- **`hooks/bash-guard.sh session`**, on every Bash call: no `git commit` on the
  default branch, and `gh pr create` needs `--draft`.
- **`bash-guard.sh reviewer` / `validator`**, in the agents' frontmatter: the
  readiness reviewer runs read-only commands only; the validator can run the
  repo's checks but can't change git state or call `gh`.

`plan-work/references/` is shared: renaming or moving a file there breaks the
skills and agents listed above.

## Plan → work workflow

```
/plan-work  →  drafts → readiness review (max 3 rounds) → tickets created in the tracker
/work-work  →  per ticket: ticket.md → herdr worktree → worker Claude → validator → draft PR + demo media
you         →  review the draft PR; iterate in the worker pane or via PR comments
```

Fixed assumptions: Claude Code, [herdr](https://herdr.dev) (`work-work` runs inside it),
and GitHub with the `gh` CLI (`gh stack` optional). The tracker, check commands and
demo tooling are discovered per project. Decisions made while a ticket is worked
go into its `ticket.md` first and are written back to the tracker, so the
validator always checks against the current contract. For demo videos `work-work` uses the
project's own demo skill, or the `record-video` skill from
agent-video-recorder if `avr` is installed.

If a skill seems missing, check the repo you're in: skills under a project's own
`.claude/skills/` travel with that clone, not with the workbench.
