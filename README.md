# dotfiles

My portable setup: the Claude Code harness (skills, agents, settings) and the
terminal around it (Ghostty, herdr, Starship, btop, LazyVim, bash), themed
Catppuccin Macchiato. On a new machine, start with
[docs/setup.md](docs/setup.md): packages for Arch and Debian/Ubuntu, then this
installer.

```sh
git clone https://github.com/krav4enkodm/dotfiles ~/Projects/dotfiles
~/Projects/dotfiles/install.sh --check   # what would change
~/Projects/dotfiles/install.sh           # roll it out
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
| `claude/settings.json` | `~/.claude/settings.json` | merged; model, permissions and deny rules, hooks, status line, plugins, Remote Control on for every session |
| `claude/settings-removed.json` | `~/.claude/settings.json` | keys (dotted paths) deleted after the merge |
| `claude/mcp-servers.json` | `~/.claude.json` → `mcpServers` | merged |
| `config/*` | `~/.config/*` | copied: Ghostty, Starship, herdr, the btop theme, LazyVim's colorscheme, `dotfiles/bashrc.sh` |
| `config/btop/btop.conf` | `~/.config/btop/btop.conf` | only these keys set; btop rewrites the file itself |
| `config/nvim/lazyvim.json` | `~/.config/nvim/lazyvim.json` | extras added; LazyVim starter cloned first if `~/.config/nvim` is missing |
| — | `~/.bashrc` | one line added that sources `~/.config/dotfiles/bashrc.sh` |

## Skills

| Skill | What it does | Depends on |
|---|---|---|
| `commit` | Commits following the conventions of whatever repo you're in, detected from its history. Title = what changed, body = why. | — |
| `work-plan` | Turns an idea or rough ticket into tickets that meet a Definition of Ready, grounded in the codebase, and links them into waves so as much as possible can be built in parallel. Works with Linear, Jira, GitHub Issues or markdown files. | `readiness-reviewer` agent |
| `work-work` | Runs only as `/work-work`. Runs a plan or a set of ready tickets: each ticket starts in its own herdr worktree with a separate Claude worker as soon as its blockers allow, is checked by an independent validator, and gets a draft PR. | `work-plan` (`definition-of-ready.md`, `trackers.md`, `design.md`), `ticket-validator` agent, herdr |
| `open-pr` | Opens or rewrites a PR description, following the repo's PR template when it has one; attaches screenshots and demo videos with `gh --attach`; handles `gh stack` stacks. | `gh stack` (optional) |
| `work-retro` | Runs only as `/work-retro`, in a ticket's worker pane after its PR merges. Finds every point where you had to step in (pane messages, decisions added to `ticket.md`, PR review comments) and proposes the fix that would have made it unnecessary. Project fixes are applied in place; dotfiles fixes go to a local inbox. | `work-work` (`worker-brief.md`, `ticket.md` amendments), `work-plan` (`definition-of-ready.md`, `review-checklist.md`, `design.md`), `jq` |

## Repo-only skills

These live in `.claude/skills/` and load only in sessions opened in this repo. The installer doesn't copy them.

| Skill | What it does |
|---|---|
| `work-retro-apply` | Runs only as `/work-retro-apply`. Reads the inbox `work-retro` fills, groups findings across tickets, flags any that came back after an earlier fix, and turns the picked ones into one draft PR in generic wording. |

## Agents

| Agent | Used by | What it does | Depends on |
|---|---|---|---|
| `readiness-reviewer` | `work-plan` | Checks a ticket's claims against the code and returns gaps and questions. | `work-plan` (`review-checklist.md`, `definition-of-ready.md`, `design.md`), `bash-guard.sh` hook, Figma plugin |
| `ticket-validator` | `work-work` | Checks a branch against its ticket using only the ticket, the diff and the running app; returns PASS or FAIL with a gap list. | `work-plan` (`design.md`), `bash-guard.sh` hook, Figma plugin, `chrome-devtools` MCP (UI tickets) |

## Rules

| Rule | Loads for | What it says |
|---|---|---|
| `code-comments` | `*.ts`, `*.tsx` | No comments that narrate the code; keep directives and short "why" notes. |
| `frontend-feature-layers` | `*.tsx`, `*.jsx` | Lay out a data-backed React feature as data / services / presentational components / thin container. |

## Guardrails

Things that must never happen are enforced, not just written down. They match
the usual form of a command, so treat them as guardrails, not a sandbox.

- **Deny rules** in `settings.json`: no `gh pr merge`, `gh pr ready`,
  `gh stack merge`, `gh stack unstack`, or `gh stack submit --open`. Run those
  yourself.
- **Ask rules** in `settings.json`: posting on GitHub (`gh pr comment`,
  `gh issue comment`, `gh pr review`, and `gh api` calls on comments, reviews
  or GraphQL) always asks for approval, even in auto mode.
- **`hooks/bash-guard.sh session`**, on every Bash call: no `git commit` on the
  default branch, and `gh pr create` needs `--draft`.
- **`bash-guard.sh reviewer` / `validator`**, in the agents' frontmatter: the
  readiness reviewer runs read-only commands only; the validator can run the
  repo's checks but can't change git state or call `gh`.

`work-plan/references/` is shared: renaming or moving a file there breaks the
skills and agents listed above.

## Plan → work workflow

```
/work-plan  →  drafts → dependency graph + waves → readiness review (max 3 rounds) → tickets + wave table in the tracker
/work-work  →  per ticket, once its blockers pass (or merge, for 2+): ticket.md → herdr worktree → worker Claude → validator → draft PR + demo media
you         →  review and merge the draft PRs; iterate in the worker panes or via PR comments
/work-retro →  in the merged ticket's pane: where you stepped in → project fixes now, dotfiles fixes to ~/work-work/retros/inbox.md
/work-retro-apply → in the dotfiles repo: inbox → grouped findings → one draft PR here
```

Fixed assumptions: Claude Code, [herdr](https://herdr.dev) (`work-work` runs inside it),
and GitHub with the `gh` CLI (`gh stack` optional). The tracker, check commands and
demo tooling are discovered per project. Decisions made while a ticket is worked
go into its `ticket.md` first and are written back to the tracker, so the
validator always checks against the current contract. For demo videos `work-work` uses the
project's own demo skill, or the `record-video` skill from
agent-video-recorder if `avr` is installed.

If a skill seems missing, check the repo you're in: skills under a project's own
`.claude/skills/` travel with that clone, not with the dotfiles repo.
