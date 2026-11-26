---
paths:
  - "**/*.{ts,tsx}"
---

# Honest types

Types describe what the data really is; never bend the code to fit a loose
type. The schema and generated types are the source of truth. The repo's own
rules win where they differ.

- **Check the generated type before handling absence.** No `?? ''`, `|| 0` or `?.`
  on a value the schema says is always there: a fallback hides what the data is.
- **Required unless a real case needs it optional.** `x?: T` and `x: T | null`
  mean different things; match the schema. An argument or prop the code can't
  work without is required.
- **Narrow, don't cast.** Filter nullish items with a type predicate
  (`(x): x is T => x != null`) or fix the upstream type instead of
  `as T`, `map(x => x) as T[]`, `!` or `@ts-ignore`. A cast that stays needs a
  one-line reason.
- **Derive, don't duplicate.** Use the fragment, schema, enum or library type
  (`ButtonProps['size']`) instead of a hand-written copy, so upstream changes
  propagate. For a long `Pick<>` of a query type, add a fragment.
- **Enums over string literals** for values the backend defines.
- **Avoid exhaustive `Record<BackendEnum, …>` maps** when the backend can add
  values; they break the build when the enum grows. Handle the unknown case.
- **Let TS infer** obvious generics and return types (`useState<string>()`, not
  `useState<string | undefined>(undefined)`). Use `import type` for types.
- **One return type per function.** A function returning `string | false` is
  doing two jobs (validate and describe); split it.
- **Services return `T | undefined`** and let the UI decide how to show absence.
