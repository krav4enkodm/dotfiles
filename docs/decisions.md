# Decisions

Why the dotfiles repo is built the way it is. For using it, see the [README](../README.md).

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
4. **Copies `config/` into `~/.config/`** the same way, with its own manifest at
   `~/.config/dotfiles/.manifest`. Two files are merged, not copied, because
   their tools rewrite them: `btop.conf` (only the repo's `key = value` lines are
   set) and LazyVim's `lazyvim.json` (the repo's extras are added; extras turned
   on locally stay). Shell setup lives in `~/.config/dotfiles/bashrc.sh`, and
   `~/.bashrc` gets one line that sources it, so whatever else installers append
   to `~/.bashrc` keeps working.
5. **Sets up integrations:** herdr's Claude integration, the `gh stack` extension
   (`github/gh-stack`), herdr's worktree-setup plugin, plugin marketplaces and the enabled plugins, through
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
  Ask rules cover what's fine only when I asked for it, like posting on
  GitHub: a deny would block the post I did ask for.
- **Agents' read-only promise** is a frontmatter hook, because nothing else
  works here: `permissionMode` is overridden in auto mode, and
  `disallowedTools: Bash(...)` removes Bash entirely.

This is also why the dotfiles repo isn't a plugin: plugin subagents ignore
`hooks`, `permissionMode` and `mcpServers` in their frontmatter.

## work-plan is a coordinator with phases

`work-plan` used to be one skill that sized, drafted, reviewed and asked in a
single context. Two things went wrong with that: on bigger work the context
filled up before the split, and the agent cut tickets from whatever it had
understood, so a misunderstanding only showed in the tickets. Now:

- **Phases are separate skills with `context: fork`.** Each starts clean and
  reads the plan folder, so the coordinator's context holds only summaries and
  a plan survives `/clear`. They're `user-invocable: false`: the user types one
  command.
- **Only the coordinator asks.** A forked skill can't hold a conversation with
  the user, and questions spread over five contexts are hard to follow. Phases
  write `questions.md` and return; the coordinator asks and re-runs the phase
  to apply the answers.
- **Understanding is approved before splitting.** The brief (Example Mapping:
  rules, Given/When/Then examples, open questions) and the contracts each get
  a gate. Contracts come before tickets because they are what make parallel
  tickets possible.
- **Gates and checks are a script**, `work-plan/scripts/plan.mjs`, for the
  same reason guardrails are hooks: prose is a request. It stamps each phase
  with a hash of its inputs, so editing a file by hand makes exactly the later
  phases stale, like make; and it checks waves, cycles, overlap inside a wave
  and that every brief, inventory and contract item is owned by a ticket.
  `tests/work-plan/run.sh` tests it from `check.sh`.
- **Plans live in `~/work-work/plans/<slug>/`**, not under one repo, because a
  plan can span a frontend and its API. `work-work` still runs per repo and
  picks its rows from the wave table's Repo column.

## Claude's browser

The `chrome-devtools` MCP launches its own Chromium instead of attaching to
one on a debugging port, which meant starting a browser by hand before every
browser task. It runs headless, so it never takes focus from what I'm doing,
and uses the MCP's default profile (`~/.cache/chrome-devtools-mcp/`), so
sign-ins persist between sessions and my own browser is never involved. The
`chrome-devtools` allow rule lets it work without a prompt per click.

Signing that browser in to an app is the `agent-login` skill. Credentials stay
in 1Password: a per-app env file in `~/.config/agent-login/` holds only
`op://` references, and `op run` resolves them into the environment of one
script, which types them into the login form over the debugging port. Claude
never sees the values, so they can't leak into transcripts, and nothing secret
sits on disk. The env files stay out of the repo because vault and item names
are personal. The cost of the port (`--remote-debugging-port=9333`) is that any
local process can drive the signed-in browser while it runs; it listens on
localhost only and closes with the MCP.

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
- **Packages.** The installer lays down configs, not software: installing
  differs per distro and needs root, so [setup.md](setup.md) lists the commands
  instead. `install.sh` only warns when a tool is missing.
- **Configs I haven't changed from the defaults.** lazygit, LazyVim's own
  options and keymaps, and the rest of btop's settings stay stock, so there's
  nothing to carry. A file goes into `config/` only once it differs from what
  the tool ships with.
- **The desktop.** The window manager, desktop shell, login screen and drivers
  are tied to the hardware and change more often than the terminal setup.

## Keep it publishable

Everything here, commit messages and PR descriptions included, is kept free of
employer internals so the repo can go public without a scrub. Make examples
generic before adding them, not after.
