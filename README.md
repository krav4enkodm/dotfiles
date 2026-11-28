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
| `work-plan` | Turns an idea or rough ticket into tickets that meet a Definition of Ready, grounded in the codebase, across one or more repos, and links them into waves so as much as possible can be built in parallel. One command coordinates the phases below, asks every question, stops at each gate, and keeps the plan on disk (`~/work-work/plans/<slug>/`) so it resumes and re-runs from any phase. Works with Linear, Jira, GitHub Issues or markdown files. | the `work-plan-*` phase skills, `scripts/plan.mjs` (Node) |
| `work-plan-recon` | Phase of `work-plan`, not run by hand: maps each repo, and the design into a UI inventory. | `work-plan` (`plan-files.md`, `design.md`), Figma plugin for Figma designs |
| `work-plan-brief` | Phase of `work-plan`: goal, flows, rules with Given/When/Then examples, and a data map checked against the code; every unknown becomes a fact, a decision or a question. | `work-plan` (`plan-files.md`) |
| `work-plan-contracts` | Phase of `work-plan`: fixes the shapes parallel tickets share (API, view-models, props, fixtures) before any ticket exists. | `work-plan` (`plan-files.md`) |
| `work-plan-split` | Phase of `work-plan`: cuts brief and contracts into ticket drafts and waves, until `plan.mjs check` passes. | `work-plan` (`plan-files.md`, `definition-of-ready.md`, `design.md`) |
| `work-plan-review` | Phase of `work-plan`: one readiness-review round per run, fixing what the code settles and recording the rest as questions. | `work-plan` (`review-checklist.md`, `definition-of-ready.md`), `readiness-reviewer` agent |
| `work-work` | Runs only as `/work-work`. Runs a plan or a set of ready tickets: each ticket starts in its own herdr worktree with a separate Claude worker as soon as its blockers allow, is checked in parallel by independent agents against its ticket, the coding rules and, for UI tickets, the design, and gets a draft PR. | `work-plan` (`definition-of-ready.md`, `trackers.md`, `design.md`), `ticket-validator`, `rules-reviewer` and `design-validator` agents, herdr |
| `work-clean` | Runs only as `/work-clean`. Removes the herdr worktrees whose PRs have merged: closes the workspace, removes the checkout and deletes the local branch. Skips any worktree with uncommitted changes, commits beyond the merged PR, or a working agent. | herdr, `gh` |
| `open-pr` | Opens or rewrites a PR description, following the repo's PR template when it has one; attaches screenshots and demo videos with `gh --attach`; handles `gh stack` stacks. | `gh stack` (optional) |
| `pr-review` | Reviews a PR or branch, someone else's or your own: resolves the refs, fetches the PR head without checking it out, gathers the description and ticket, and hands them to the `pr-reviewer` agent so the diff never fills the conversation. Relays a verdict and findings by severity, each with its cost and a fix; never posts. | `pr-reviewer` agent, `gh` |
| `agent-login` | Signs Claude's browser in to a web app with a username and password from 1Password: `op run` hands them to a script that types them into the login form, so they never enter the conversation. One env file of `op://` references per app in `~/.config/agent-login/`. | `chrome-devtools` MCP (debugging port 9333), 1Password CLI |

## Agents

| Agent | Used by | What it does | Depends on |
|---|---|---|---|
| `readiness-reviewer` | `work-plan-review` | Checks a ticket's claims against the code and returns gaps and questions. | `work-plan` (`review-checklist.md`, `definition-of-ready.md`, `design.md`), `bash-guard.sh` hook, Figma plugin |
| `ticket-validator` | `work-work` | Checks that a branch implements its ticket, using only the ticket and the diff, and runs the repo's checks; returns PASS or FAIL with a gap list. | `bash-guard.sh` hook |
| `design-validator` | `work-work` | For tickets with a Design section: checks the UI against the design, by Figma values row by row, by the node's screenshot where the file has no values, or by the elements on an image mockup; returns PASS or FAIL with a gap list. | `work-plan` (`design.md`), `bash-guard.sh` hook, Figma plugin, `chrome-devtools` MCP |
| `pr-reviewer` | `pr-review` | Reviews one change against its ticket and every frontend, backend and repo rule its paths match: a runtime pass for backend files (failures, retries, idempotency, races, data safety, rollout) and a design pass for every file. Returns a verdict and findings by severity, each with its cost and a fix. | the frontend and `backend-*` rules, `bash-guard.sh` hook |
| `rules-reviewer` | `work-work` | Finds the CLAUDE.md, AGENTS.md and rule files that apply to a branch's changed files and checks the changed lines against them; returns PASS or FAIL with violations, plus non-blocking notes. | `bash-guard.sh` hook |

## Rules

| Rule | Loads for | What it says |
|---|---|---|
| `code-comments` | JS/TS source | No comments that narrate the code; keep directives, one-line "why" notes and ticketed TODOs. |
| `frontend-feature-layers` | `*.tsx`, `*.jsx` | Lay out a data-backed React feature as data / services / presentational components / thin container. |
| `typescript-types` | `*.ts`, `*.tsx` | Types say what the data is: trust the schema's nullability, required unless a caller omits it, narrow instead of casting, derive from generated types. |
| `react-components` | `*.tsx`, `*.jsx` | The parent decides rendering, required callbacks, shared components know nothing of their callers, balanced props and slots, fixed variants, no wrappers without value, design system first. |
| `react-state-and-data` | `*.tsx`, `*.jsx`, `useX.ts` | One source of truth, handlers over effects, memoize only for a real problem, form state mirrors the mutation input, fetch where the flow starts, every loading and error state. |
| `code-clarity` | JS/TS source | No unexplained code, lint as a strong default, when to extract and when to inline, positive booleans and domain names, the traps (zero, money, empty lists). |
| `package-boundaries` | JS/TS source, `package.json`, `tsconfig*.json` | Public entry points, no own-index imports, dependencies point one way, honest manifests. |
| `frontend-tests` | tests, stories, mocks | Right level, cover what you added, tests that fail when behaviour breaks, select the way a user finds the element, typed mocks next to what they mock. |
| `graphql-client` | `*.graphql`, `*.tsx`, `*.jsx`, `useX.ts` | Only in repos with a GraphQL client: props typed from fragments, reuse queries and fragments, cache updates after mutations, mocks typed with fragment types. |
| `backend-reliability` | backend source | Decide what each failure means, idempotent retries, publish after commit, atomic updates, never guess a match, no silent outcomes. |
| `backend-data` | backend source, SQL, migrations | Let the database do the work, bounded lists, no N+1, expand/migrate/contract, constraints match validations, trace personal data to every sink. |
| `backend-design` | backend source | Logic lives with its concept, variants own their behaviour, config as data, simple over clever, build for today with a cheap shape for tomorrow, API contracts for the consumer. |
| `backend-tests` | backend tests | Each behaviour once at its own layer, cover the risky paths, tests that fail when it breaks, real wiring, minimal deterministic setup. |

The frontend rules are distilled from ~1,200 of my review comments (2022–2026),
the backend rules from ~1,300 review comments by two senior backend reviewers:
each states a pattern raised repeatedly or held when an author pushed back.
The general rules stay API-agnostic; what only holds for one API style lives in
its own rule (`graphql-client`), so a REST counterpart can sit next to it.

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
  readiness, rules and PR reviewers run read-only commands only; the ticket and
  design validators can run the repo's checks and the app but can't change git
  state or call `gh`.

`work-plan/references/` is shared: renaming or moving a file there breaks the
skills and agents listed above.

## Plan → work workflow

```
/work-plan  →  recon → brief ✋ → contracts ✋ → split → review (max 3 rounds) ✋ → tickets + wave table in the tracker
/work-work  →  per ticket, once its blockers pass (or merge, for 2+): ticket.md → herdr worktree → worker Claude → ticket, rules and design validators in parallel → draft PR + demo media
you         →  review and merge the draft PRs; iterate in the worker panes or via PR comments
/work-clean →  remove the worktrees, workspaces and local branches of merged PRs
```

✋ marks the gates where `work-plan` stops for your approval. Every phase runs
in a forked context and reads only the plan folder, so a plan survives `/clear`
and can be picked up with `/work-plan <slug>`; editing a file there by hand
makes the phases after it stale, and they run again. `/work-plan <slug> status`
shows where a plan stands.

Fixed assumptions: Claude Code, [herdr](https://herdr.dev) (`work-work` runs inside it),
and GitHub with the `gh` CLI (`gh stack` optional). The tracker, check commands and
demo tooling are discovered per project. Decisions made while a ticket is worked
go into its `ticket.md` first and are written back to the tracker, so the
validator always checks against the current contract. For demo videos `work-work` uses the
project's own demo skill, or the `record-video` skill from
agent-video-recorder if `avr` is installed.

If a skill seems missing, check the repo you're in: skills under a project's own
`.claude/skills/` travel with that clone, not with the dotfiles repo.
