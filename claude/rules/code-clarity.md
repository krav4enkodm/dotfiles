---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs,py,go,rb,java,kt,swift,rs,php,cs}"
---

# Code that tells a story

Code should read without investigating how each helper works. Simplicity beats
cleverness, and beats satisfying a lint rule (prefer a justified disable over
contorted code). The repo's own rules win where they differ.

- **Name booleans positively.** `showFilters`, not `hideFilters` used as
  `!hideFilters`; `hasItems = a || b`, not `noItems = !a && !b`.
- **Make branches explicit.** `cond ? f(x, m) : f(x)` beats `f(x, cond ? m : undefined)`:
  the reader shouldn't have to know that `undefined` means "skip".
- **Name a condition or expression used twice**, so a later change can't miss a
  copy.
- **Names follow the domain and the schema.** Name by meaning, not appearance
  (`WarningAlert`, not `YellowAlert`). Follow platform conventions (`disabled`,
  `onSuccess`/`onFailure`). A boolean is `isX`/`hasX`, never a verb. Rename
  what you copied.
- **No magic values:** use enums, route constants and shared constants such as
  a "no value" placeholder or a debounce interval.
- **Use the method that says what you mean:** `some` for a yes/no, `filter`
  when there can be several matches, a map or set for lookups inside loops.
- **Don't add an abstraction for one caller.** Inline it, unless it isolates
  real complexity.
- **Reuse before writing.** Search for an existing helper, service or constant.
  Pure logic goes in a service with a unit test.
- **Respect package boundaries.** Import other packages through their public
  entry point. Inside a package, don't import from its own index (it hides
  cycles). Put domain code in its domain, not in shared top-level libraries.
  Test-only tooling goes in dev dependencies.
- **Keep the change to its ticket.** Note anything out of scope for a follow-up
  rather than fixing it in passing.
- **Leave nothing behind:** debug output, unused exports, translation keys, enum
  values, dependencies or query fields left after a removal.
