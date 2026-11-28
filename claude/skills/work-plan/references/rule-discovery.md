# Finding the rules that apply to a change

Used by every reviewer that checks code against the coding rules
(`rules-reviewer`, `pr-reviewer`). Don't rely on which rules happen to be loaded
in your own context: find them from the changed files.

## Candidates

List the changed files (`git diff --name-status <base>...<head>`), collect
candidates from every level, and keep the ones that apply to at least one
changed file:

| Source | Applies to |
|---|---|
| `~/.claude/CLAUDE.md` | every file |
| `~/.claude/rules/**/*.md` | files matching its `paths:` frontmatter; every file if it has none |
| `CLAUDE.md`, `AGENTS.md`, `CLAUDE.local.md` at the repo root, and `.claude/CLAUDE.md` | every file in the repo |
| `CLAUDE.md` / `AGENTS.md` in a subdirectory | files under that directory |
| `<repo>/.claude/rules/**/*.md` | files matching its `paths:`; every file if it has none |

- Match `paths:` globs against the changed paths relative to the repo root.
- Read every rule that matches, in full, and follow `@path` imports inside it
  one level deep.
- A rule that opens with a condition ("only for a repo that…") applies only when
  the repo meets it. Check the repo, not the file name.
- Keep only guidance about the code itself. Process rules (git, commits, PRs,
  posting on GitHub, which commands to run) are not code rules.

## Precedence

When two rules disagree:
- the repo's rules beat the user's;
- a closer directory's file beats a farther one;
- an explicit rule beats the neighbouring code, except where the rule itself
  says to match the neighbours.

If you can't tell which wins, don't report a breach of either: list the
conflict, quoting both.

## Report

Say which rule files you applied to which changed files, so a missed rule can be
told apart from a rule that was found and judged met.
