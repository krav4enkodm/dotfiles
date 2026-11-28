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
  already gives, a `?.` or fallback on a value a guard above already checked.
- **Remove what nothing uses:** props, hook return fields, query fields,
  constants, exports. When you rename, replace or move something, update every
  remaining use and delete the old copy.
- **Lint rules are strong defaults, not laws.** Try to satisfy the rule first:
  a size or complexity warning means split the code, an import warning means
  import through the right entry point. When satisfying one makes the code
  harder to read, disable it for that line with a one-line reason; link a
  ticket if it's a temporary workaround. In tests, readability wins outright.

## Reuse and extract

- **Search before writing.** Look for an existing helper, constant, hook or
  component in the repo, its shared libraries and the libraries already
  installed (a `noop`, a formatter, an empty-value placeholder, the repo's own
  wrapper around a third-party widget, which often carries fixes such as time
  zones or sanitising), and name what you reused in your reply. When a near-copy
  would differ in two or three values, make those parameters of the existing
  piece instead.
- **Name a condition used twice**, so the copies can't drift apart. A value two
  places must agree on (a page size in the query and in the paginator) is one
  constant.
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
- **Several arguments, or any boolean or optional one, become one options
  object:** `build({ owner, isDraft })`, not `build(owner, true, false)`,
  which can't be read at the call site. A single argument stays plain.
- **A fallback lives in the parameter default, once** (`maxLines = Infinity`),
  not as `x ? x : LIMIT` in the body or a "no limit" value every caller passes.

## Read like the domain

- **Positive booleans.** `showFilters`, not `hideFilters` used as
  `!hideFilters`; a helper for the case the code checks (`isWeekly(x)`, not
  `!isMonthly(x)`).
- **Make the business condition visible at the call site.**
  `isMember ? applyDiscount(price, rate) : price` beats
  `applyDiscount(price, isMember ? rate : undefined)`.
- **Return early** when data is missing or the uninteresting case holds, then
  handle the main case unnested. A special case gets its own explicit branch.
- **No magic values:** enums, route helpers instead of hand-built paths, shared
  constants (one debounce interval for every search input, analytics event
  names in one module).
- **Names follow the domain and say what you get.** Name by meaning, not
  appearance (`WarningAlert`, not `YellowAlert`), and by what the data is, not
  the business meaning you assume from it. Rename copied code for its new
  entity, and rename a function when its purpose changes.
  - A callback is named after the event that fires it (`onSaveSuccess`), an
    emitted event after what happened (`REPORT_DELETED`), not after who
    listens (`LIST_UPDATED`).
  - A name states the scope it's valid for: a helper correct for one case says
    so, or it gets reused where it's wrong. No bare generic names (`getType`,
    `data`, `Form`) and no abbreviations (`user`, not `u`).
  - A boolean is `isX`/`hasX`; follow platform names (`disabled`, not
    `enabled`; `onSuccess`/`onFailure` as a pair). PascalCase for components
    and types, camelCase for functions and values.
- **The direct form:** `Boolean(x)` over `!!x`, `??` when only null and
  undefined should fall back, `some` for yes/no, `find` for one match, `filter`
  for many, a `Set` or `Map` for lookups inside loops. Compute what doesn't
  change outside per-item callbacks, and use `some` or `for…of` when you can
  stop early.

## Traps

- **`0` is a value.** Check `== null` explicitly when zero is valid, and guard
  parsing so `parseInt(undefined)` can't become `NaN` in the UI
  (`Number(null)` is `0`, `Number(undefined)` is `NaN`). "None" gets its own
  value (`null`, an enum member), never `''` or `0`: `!score` turns a score of
  0 into "new".
- **Missing is not zero.** Show the app's empty placeholder (such as `—`) or
  omit the row for an absent value; never a formatted fallback (`$0.00`, `?`,
  `score ?? 0`) that reads as real data.
- **Identify things by id or enum, never by display text or position.** No
  `title === '…'`, `splice(3, 1)`, tab `0`, or a label built from a code
  (`capitalize(type)`): titles change and lists get reordered. Compare ids or
  enum members, and display the label the data source provides when it has
  one.
- **Money:** never round with `toFixed` or sum floats ad hoc
  (`(1.005).toFixed(2) === '1.00'`); use one shared rounding helper for every
  total.
- **`list[0]`** on a list that can be empty.
- **No unreachable branch,** and return after handling a case so it can't fall
  through.
- **Check composed strings** for doubled or missing spaces.
