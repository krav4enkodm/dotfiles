# Decisions

Why the workbench is built the way it is. For using it, see the [README](../README.md).

## Copy and merge, not symlink

`install.sh` **copies** files and **merges** settings instead of linking them.
The clone can live anywhere, or be deleted, and nothing on the machine changes
until the installer runs again. The cost: a live edit under `~/.claude/` stays on
that machine until it's brought back into the repo. `./install.sh --check` finds
those edits, and the next `./install.sh` overwrites them after backing them up.

## What the installer does

1. **Checks prerequisites.** `git` and `jq` are required. It warns about `claude`,
   `gh` (plus `gh auth`), `herdr`, `npx` and `avr`.
2. **Copies files** (the global CLAUDE.md, skills, agents, rules, hooks, the status line script) into `~/.claude/`.
   It records what it installed in `~/.claude/.workbench-manifest`, so a skill
   deleted from the repo is removed on the next run. Skills it didn't install
   are left alone.
3. **Merges settings** into the live files instead of replacing them. Repo keys
   win, and keys added locally by other tools (herdr's hook, `autoMode`, ...)
   are kept. Objects merge deeply, arrays are replaced, except hook lists (see
   below). Removing a key from the
   repo does not remove it on the machine; to retire a key everywhere, also list
   it in `settings-removed.json`, which the installer deletes after the merge.
   Each machine may keep its own additions (extra plugins, MCP servers), so
   `--check` only reports where the machine differs from what the repo sets.
4. **Sets up integrations:** herdr's Claude integration, the `gh stack` extension
   (`github/gh-stack`), plugin marketplaces and the enabled plugins, through
   `herdr integration`, `gh extension` and `claude plugin`.

Hook scripts are managed one file at a time, because herdr keeps its own
script in `~/.claude/hooks/`. In settings, each `hooks.<event>` is an array of
entries keyed by `matcher`. The repo's entries replace local entries with the
same matcher; local entries with any other matcher are kept after them, so a
tool that adds its own `PreToolUse` hook on one machine keeps it. Events the
repo doesn't set merge as separate keys.

Anything it replaces or removes goes to `~/.claude/backups/install-<timestamp>/`.
Re-running it is safe.

## Which Claude Code feature holds what

- **CLAUDE.md** holds rules for every session; **`rules/`** holds conventions
  for particular files, scoped with `paths:` so they load only when Claude
  touches matching files. `frontend-feature-layers` was a skill and is now a rule:
  it's a convention, and a skill applies only when the model decides to load it.
- **Skills** hold procedures. A skill with side effects that should never start
  on its own (`work-work`) sets `disable-model-invocation: true`. `commit` and
  `open-pr` stay model-invocable because `work-work`'s workers call them
  through the Skill tool.
- **Deny rules and hooks** hold anything that must never happen. Prose in
  CLAUDE.md is a request; it stays there so Claude plans around the rule, but
  the hook is what enforces it. Deny rules cover fixed commands; the hook
  covers rules that depend on state or flags (the current branch, `--draft`).
- **Agents' read-only promise** is a frontmatter hook, because nothing else
  works here: `permissionMode` is overridden in auto mode, and
  `disallowedTools: Bash(...)` removes Bash entirely.

This is also why the workbench isn't a plugin: plugin subagents ignore
`hooks`, `permissionMode` and `mcpServers` in their frontmatter.

## What is deliberately not here

- **Plugin code.** Claude Code installs and updates plugins itself. `settings.json`
  lists which are enabled and `install.sh` installs any that are missing.
  Vendoring the cache would fight the updater.
- **Machine-specific settings.** herdr's `SessionStart` hook (herdr installs and
  updates it) and the `autoMode` environment block stay local. The settings merge
  leaves them in place.
- **Credentials, history, sessions, project state:** `~/.claude/.credentials.json`,
  `history.jsonl`, `projects/`, `sessions/`, `session-env/`, `todos/`. They're
  machine-local, secret, or both.
- **`~/.claude.json` as a whole.** It mixes real config with `oauthAccount`,
  `userID`, telemetry and per-project caches. Only `mcpServers` is portable, which
  is why it's merged rather than replaced.
- **Employer-specific skills.** Anything that refers to internal package names,
  private wikis or in-house design systems stays in the relevant work repo or
  unversioned in `~/.claude/skills/`.
- **Repo-scoped skills.** Skills under a project's own `.claude/skills/` travel
  with that clone.
- **Shell dotfiles and toolchain.** Out of scope for now: this repo covers the
  Claude harness only.

## Keep it publishable

Everything here, commit messages and PR descriptions included, is kept free of
employer internals so the repo can go public without a scrub. Make examples
generic before adding them, not after.
