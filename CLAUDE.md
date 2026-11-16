# dotfiles

My portable Claude Code setup. `claude/` mirrors `~/.claude/`, and `install.sh`
copies and merges it onto the machine. See README.md for the file map and
docs/decisions.md for how the installer works and what is deliberately left out.

## Rules

- **The repo is the source of truth.** Edit files here, never under `~/.claude/`,
  then run `./install.sh`. Run `./install.sh --check` first: if it reports drift,
  ask whether to copy the live change back into the repo before installing over it.
- **Keep it publishable.** No employer internals anywhere, including commit
  messages and PR descriptions: no in-house design systems, product terms,
  ticket keys, internal URLs or package names. Use generic examples.
- **Skills depend on each other through `work-plan/references/`.** `work-work` and
  both agents read files from there. When renaming or moving any of them, update
  every reference (`grep -rn 'work-plan/' claude/`) and the "Depends on" columns
  in README.md.
- **Keep README.md in step** when adding, removing or renaming a skill or agent.
- **Run `./check.sh` before committing.** It runs shellcheck, validates the JSON,
  matches the README tables against `claude/` and checks that links resolve.
  CI runs it on every PR.

## Git

- Branch off `main` and open a draft PR. Don't commit to `main` directly.
- Commit titles are plain imperative ("Install the gh stack extension from the
  installer"); the body explains why.
- This machine has no global git identity; each clone sets its own. On a fresh
  clone run `git config user.name "Dmitry Kravchenko"` and
  `git config user.email krav4enkodm@gmail.com` once.
