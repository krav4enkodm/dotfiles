---
paths:
  - "**/*.{ts,tsx}"
---

# Code comments

Write TypeScript and TSX without comments that narrate the code. Names, types
and small functions carry the meaning. The repo's own rules (CLAUDE.md,
AGENTS.md, `.claude/rules/`, lint config) and its neighbouring code win where
they differ, for example a repo that documents exported props with JSDoc.

## Don't write

- Comments that restate the next line: `// fetch the user`, `// loop over items`.
- Section labels in JSX or code: `{/* Header */}`, `// --- handlers ---`.
- Notes about the change itself: `// added for X`, `// new`, `// updated logic`.
  That belongs in the commit message or PR.
- Commented-out code. Delete it; git keeps the history.
- `TODO`s that aren't tracked anywhere. Raise them in your reply instead.

## Keep

- Directives, which are code rather than commentary: `// eslint-disable-next-line`,
  `// @ts-expect-error`, `// @ts-ignore`, `// biome-ignore`, `/* webpackChunkName */`,
  `/// <reference />`, license headers.
- A short note on **why**, when the code can't say it: a workaround for a
  library bug (link the issue), a non-obvious constraint, a deliberate choice that
  looks wrong. One line, above the code it explains.
- Existing comments in code you edit. Leave them, unless your change makes them
  wrong; then fix or remove them.

Before writing a comment, try renaming, extracting a function or tightening a
type first. If the comment is still needed, it's a "why" comment.
