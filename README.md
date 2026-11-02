# workbench

My portable Claude Code setup — skills, settings, and the bits that don't come
back on their own after a fresh install.

```sh
git clone https://github.com/krav4enkodm/workbench ~/workbench
~/workbench/install.sh
```

`install.sh` symlinks everything into `~/.claude/`, so edits made on any machine
are already in the repo — commit and push, no copy-back step. Anything it would
overwrite is moved into `~/.claude/backups/install-<timestamp>/` first, and it's
safe to re-run.

## What's here

| Path | Goes to | Notes |
|---|---|---|
| `claude/skills/*` | `~/.claude/skills/*` | one symlink per skill |
| `claude/agents/*.md` | `~/.claude/agents/*.md` | one symlink per subagent |
| `claude/settings.json` | `~/.claude/settings.json` | model, permissions, status line, plugins |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | dir / branch / model / context-remaining |
| `claude/mcp-servers.json` | merged into `~/.claude.json` | via `jq`, additive |

## Skills

| Skill | What it does |
|---|---|
| `commit` | Commits following the conventions of whatever repo you're in, detected from its history. Title = what changed, body = why. |
| `frontend-feature-layers` | Separates a data-backed frontend feature into data / services / presentational components / thin container. |
| `plan-work` | Turns an idea or rough ticket into tickets that meet a Definition of Ready, grounded in the codebase. Works with Linear, Jira, GitHub Issues or markdown files. |
| `work-work` | Implements one ready ticket in its own herdr worktree with a separate Claude worker, checks it with an independent validator, and opens a draft PR. |
| `open-pr` | Opens or rewrites a PR description, following the repo's PR template when it has one; handles `gh stack` stacks. |

## Agents

| Agent | Used by | What it does |
|---|---|---|
| `readiness-reviewer` | `plan-work` | Checks a ticket's claims against the code and returns gaps and questions. |
| `ticket-validator` | `work-work` | Checks a branch against its ticket using only the ticket and the diff; returns PASS or FAIL with a gap list. |

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

## What is deliberately not here

- **Plugins** — Claude Code installs and updates these itself. `settings.json`
  records which are enabled; `install.sh` prints the two commands to restore
  them. Vendoring the cache would fight the updater.
- **Credentials, history, sessions, project state** — `~/.claude/.credentials.json`,
  `history.jsonl`, `projects/`, `sessions/`, `session-env/`, `todos/`. Machine-local
  and/or secret.
- **`~/.claude.json` wholesale** — it mixes real config with `oauthAccount`,
  `userID`, telemetry and per-project caches. Only `mcpServers` is portable, which
  is why it's merged rather than replaced.
- **Employer-specific skills** — anything referencing internal package naming,
  private wikis or in-house design systems stays out of here and lives either in
  the relevant work repo or unversioned in `~/.claude/skills/`.
- **Repo-scoped skills** — skills under a project's own `.claude/skills/` travel
  with that clone. If a skill seems missing, check the repo you're in.
- **Shell dotfiles and toolchain** — out of scope for now; this repo is the Claude
  harness only.

## Caveats

- **`settings.json` is a symlink.** If Claude Code ever replaces it with a regular
  file (some writes are atomic rename), your edits stop reaching the repo. Re-run
  `install.sh` to restore the link — it backs up the stray file first.
- **Keep it publishable.** Everything here is intentionally free of employer
  internals so this repo can go public without a scrub. Genericize before adding,
  not after.
