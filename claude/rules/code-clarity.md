---
paths:
  - "**/*.{ts,tsx,js,jsx,mjs,cjs}"
---

# Code that explains itself

## No unexplained code

- **You can explain every line you add.** No field, guard, reset, parameter,
  dependency or config without a known case for it, and nothing copied from
  elsewhere without knowing why it's there.
- **Delete what can't change the outcome:** a branch equal to the default, a
  variable that only renames an argument, a hand-built conversion the platform
  already gives.
- **Remove what nothing uses:** props, hook return fields, query fields,
  constants, exports.
- **Lint rules are strong defaults, not laws.** When satisfying one makes the
  code harder to read, disable it for that line with a one-line reason; link a
  ticket if it's a temporary workaround. In tests, readability wins outright.

## Reuse and extract

- **Search before writing.** Look for an existing helper, constant, hook or
  component in the repo, its shared libraries and the libraries already
  installed (a `noop`, a formatter, an empty-value placeholder), and name what
  you reused in your reply.
- **Name a condition used twice**, so the copies can't drift apart.
- **A compound condition becomes a function.** When a check combines several
  conditions over one object (a helper call plus a comparison), move it to a
  named, unit-tested function that takes that object:
  `isDiscountWarningShown(rateCard)`. A simple check stays inline.
- **A value used once is inlined**, so the reader doesn't scroll to find it.
  Name an expression only when it reads badly inline.
- **One job per helper.** Branch and guard at the call site; a helper that
  validates, formats and builds copy is three helpers.
- **Share only what is the same.** Reuse a component or helper that does the
  same thing; don't force a shared piece onto cases you expect to diverge.

## Read like the domain

- **Positive booleans.** `showFilters`, not `hideFilters` used as
  `!hideFilters`; a helper for the case the code checks (`isWeekly(x)`, not
  `!isMonthly(x)`).
- **Make the business condition visible at the call site.**
  `isMember ? applyDiscount(price, rate) : price` beats
  `applyDiscount(price, isMember ? rate : undefined)`.
- **Return early** when data is missing or the uninteresting case holds, then
  handle the main case unnested. A special case gets its own explicit branch.
- **No magic values:** enums, route constants, shared constants (one debounce
  interval for every search input).
- **Names follow the domain and say what you get.** Name by meaning, not
  appearance (`WarningAlert`, not `YellowAlert`). Rename copied code for its new
  entity. A boolean is `isX`/`hasX`; follow platform names (`disabled`, not
  `enabled`; `onSuccess`/`onFailure` as a pair). PascalCase for components and
  types, camelCase for functions and values.
- **The direct form:** `Boolean(x)` over `!!x`, `??` when only null and
  undefined should fall back, `some` for yes/no, `find` for one match, `filter`
  for many, a `Set` or `Map` for lookups inside loops.

## Traps

- **`0` is a value.** Check `== null` explicitly when zero is valid, and guard
  parsing so `parseInt(undefined)` can't become `NaN` in the UI.
- **Money:** never round with `toFixed` or sum floats ad hoc
  (`(1.005).toFixed(2) === '1.00'`); use one shared rounding helper for every
  total.
- **`list[0]`** on a list that can be empty.
- **No unreachable branch,** and return after handling a case so it can't fall
  through.
- **Check composed strings** for doubled or missing spaces.
