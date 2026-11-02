# workbench

My portable Claude Code setup — skills, settings, and the bits that don't come
back on their own after a fresh install.

```sh
git clone https://github.com/krav4enkodm/workbench ~/Projects/workbench
~/Projects/workbench/install.sh --check   # what would change
~/Projects/workbench/install.sh           # roll it out
```

The repo is the source of truth; `install.sh` rolls it out onto the machine.
Files are **copied**, not linked, so the clone can live anywhere (or be deleted)
and nothing on the machine changes until you run the installer again. Anything
it replaces or removes goes to `~/.claude/backups/install-<timestamp>/`, and
re-running it is safe.

### Day-to-day loop

1. Change things **in the repo**, then `./install.sh`.
2. If you tweaked something live (a skill, a setting), `./install.sh --check`
   shows the drift as a diff. Copy what you want to keep into the repo, commit,
   then run `./install.sh` so the machine matches the repo again.

### What the installer does

1. **Checks prerequisites:** `git` and `jq` are required. It warns about `claude`,
   `gh` (plus `gh auth` and `gh stack`), `herdr`, `npx` and `avr`.
2. **Copies files** (skills, agents, the status line script) into `~/.claude/`.
   It records what it installed in `~/.claude/.workbench-manifest`, so a skill
   deleted from the repo is removed on the next run. Skills it didn't install
   are left alone.
3. **Merges settings** into the live files instead of replacing them. Repo keys
   win, and keys added locally by other tools (herdr's hook, `autoMode`, ...)
   are kept. Removing a key from the repo does not remove it on the machine.
4. **Sets up integrations:** herdr's Claude integration, plugin marketplaces and
   the enabled plugins, through `herdr integration` and `claude plugin`.

## What's here

| Path | Goes to | How |
|---|---|---|
| `claude/skills/*` | `~/.claude/skills/*` | copied |
| `claude/agents/*.md` | `~/.claude/agents/*.md` | copied |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` | copied; dir / branch / model / context remaining |
| `claude/settings.json` | `~/.claude/settings.json` | merged; model, permissions, status line, plugins |
| `claude/mcp-servers.json` | `~/.claude.json` → `mcpServers` | merged |

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

- **Plugin code** — Claude Code installs and updates plugins itself. `settings.json`
  lists which are enabled and `install.sh` installs any that are missing.
  Vendoring the cache would fight the updater.
- **Machine-specific settings** — herdr's `SessionStart` hook (herdr installs and
  updates it) and the `autoMode` environment block stay local. The settings merge
  leaves them in place.
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

- **Live edits are not saved anywhere.** Since files are copies, a skill edited
  under `~/.claude/` stays on that machine until you bring it back into the repo.
  `./install.sh --check` is how you find those edits. The next `./install.sh`
  overwrites them (after backing them up).
- **Keep it publishable.** Everything here is intentionally free of employer
  internals so this repo can go public without a scrub. Genericize before adding,
  not after.
