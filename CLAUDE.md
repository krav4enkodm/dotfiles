# workbench

My portable Claude Code setup. `claude/` mirrors `~/.claude/`, and `install.sh`
copies and merges it onto the machine. See README.md for the file map.

## Rules

- **The repo is the source of truth.** Edit files here, never under `~/.claude/`,
  then run `./install.sh`. Run `./install.sh --check` first: if it reports drift,
  ask whether to copy the live change back into the repo before installing over it.
- **Keep it publishable.** No employer internals anywhere, including commit
  messages and PR descriptions: no in-house design systems, product terms,
  ticket keys, internal URLs or package names. Use generic examples.
- **Skills depend on each other through `plan-work/references/`.** `work-work` and
  both agents read files from there. When renaming or moving any of them, update
  every reference (`grep -rn 'plan-work/' claude/`) and the "Depends on" columns
  in README.md.
- **Keep README.md in step** when adding, removing or renaming a skill or agent.

## Git

- Branch off `main` and open a draft PR. Don't commit to `main` directly.
- Commit titles are plain imperative ("Install the gh stack extension from the
  installer"); the body explains why.
- This machine has no global git identity. Commit with
  `git -c user.name="Dmitry Kravchenko" -c user.email="krav4enkodm@gmail.com" commit ...`.
