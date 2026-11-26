---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
---

# Code comments

No comments that narrate the code: names, types and small functions carry the
meaning.

## Don't write

- Comments that restate the next line: `// fetch the user`, `// loop over items`.
- Section labels in JSX or code: `{/* Header */}`, `// --- handlers ---`.
- Notes about the change itself: `// added for X`, `// new`, `// updated logic`.
  That belongs in the commit message or PR.
- Multi-line explanations or JSDoc on every prop, unless the repo does that.

## Keep

- Directives, which are code rather than commentary: `// eslint-disable-next-line`,
  `// @ts-expect-error` with a reason, `// biome-ignore`, `/* webpackChunkName */`,
  `/// <reference />`, license headers.
- A one-line **why**, above the code it explains, when the code can't say it: a
  workaround for a library bug (link the issue), a non-obvious constraint, a
  deliberate choice that looks wrong.
- A `TODO` that names its ticket, in the repo's format, next to each place it
  applies. Without a ticket, raise it in your reply instead.
- Existing comments in code you edit, unless your change makes them wrong; then
  fix or remove them.

Before writing a comment, try renaming, extracting a function or tightening a
type. If the comment is still needed, it's a "why" comment.
