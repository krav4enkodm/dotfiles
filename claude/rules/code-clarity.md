---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
---

# Code that explains itself

Code should read without investigating how each helper works. Simplicity
beats cleverness, and beats satisfying a lint rule: a justified disable is
better than contorted code. The repo's own rules win where they differ.

## No unexplained code

- **You can explain every line you add.** No field, guard, reset, parameter,
  dependency or config without a known case for it, and nothing copied from
  elsewhere without knowing why it's there.
- **Delete what can't change the outcome:** a null check on a value that's
  never null, `?.` after a guard, a branch equal to the default, a variable that
  only renames an argument, a hand-built conversion the platform already gives.
- **Remove what nothing uses:** props, hook return fields, query fields,
  constants, exports.

## Reuse before writing

- **Search first.** Before writing a helper, constant, hook or component, look
  for an existing one in the repo, its shared libraries and the libraries
  already installed (a `noop`, a formatter, an empty-value placeholder), and
  link it in your summary.
- **Logic goes in a named, tested service.** Non-trivial conditions, mappers,
  parsers and validators move out of components into small functions with unit
  tests.
- **One job per helper.** Branch and guard at the call site; a helper that
  validates, formats and builds copy is three helpers. Split by scenario, but
  don't scatter one flow across many tiny services.
- **Share only what is the same.** Reuse a component or helper that does the
  same thing; don't force a shared piece onto cases you expect to diverge.
- **No abstraction for one caller.** Inline it unless it isolates real
  complexity.

## Read like the domain

- **Positive booleans.** `showFilters`, not `hideFilters` used as
  `!hideFilters`; a helper for the case the code checks (`isWeekly(x)`, not
  `!isMonthly(x)`). `x !== 0`, not `!(x === 0)`.
- **Make the business condition visible at the call site.**
  `isMember ? applyDiscount(price, rate) : price` beats
  `applyDiscount(price, isMember ? rate : undefined)`.
- **Return early** when data is missing or the uninteresting case holds, then
  handle the main case unnested. A special case gets its own explicit branch.
- **Name a value or condition used twice,** so a later change can't miss a copy.
- **No magic values:** enums, route constants, shared constants (one debounce
  interval for every search input).
- **Names follow the domain and say what you get.** Name by meaning, not
  appearance (`WarningAlert`, not `YellowAlert`). Rename copied code for its new
  entity. A boolean is `isX`/`hasX`; follow platform names (`disabled`, not
  `enabled`; `onSuccess`/`onFailure` as a pair). Only components are PascalCase.
- **The direct form:** `Boolean(x)` over `!!x`, `cond && x` over
  `cond ? x : false`, `??` when only null and undefined should fall back,
  `some` for yes/no, `filter` when several items can match, a `Set` or map for
  lookups inside loops.

## Traps

- **`0` is a value.** Check `== null` explicitly when zero is valid, and guard
  parsing so `parseInt(undefined)` can't become `NaN` in the UI.
- **Money:** never round with `toFixed` or sum floats ad hoc
  (`(1.005).toFixed(2) === '1.00'`); use one shared rounding helper for every
  total.
- **`list[0]`** on a list that can be empty; `find` where several matches are
  possible.
- **Every branch can run**, and a handler stops after the case it handled.
- **Stray whitespace** in composed strings and copy.

## Comments

See `code-comments`. In short: no narrating comments. A "why" is one line, or
goes in the PR description. A workaround or placeholder you leave gets
`// TODO: [TICKET-123] …` next to each occurrence, never a TODO without a ticket.
