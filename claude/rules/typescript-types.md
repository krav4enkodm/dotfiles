---
paths:
  - "**/*.{ts,tsx}"
---

# Honest types

Types say what the data really is. The schema and the generated types are the
source of truth; bend the code to the types, never the types to the code.

- **Check the generated type before handling absence.** No `?? ''`, `|| 0`,
  `?.` or `x && format(x)` on a value the schema says is always there, or that
  a guard or the parent already ruled out: the fallback hides what the data is
  and suggests a case that can't happen. A `typeof x === 'string'` check on a
  `string` is the same smell; if the type really is unknown, type it `unknown`.
- **Required unless a real caller omits it.** Don't make a prop or field
  optional to skip a check, or because its parent object is optional. A
  nullable schema field is a required `T | null`, not `x?: T`. When every
  caller ensures a value exists, the helper takes `from: number`, not
  `from?: number`.
- **Narrow, don't cast.** No `as T`, `!` or `@ts-ignore` to quiet the checker:
  a cast on a nullable value turns `null` into a runtime crash, and
  `{…} as Record<…>` accepts any wrong key. Filter nullish items once with a
  type predicate (`items.filter((x): x is Item => x != null)`), request the
  missing field from the API, or fix the type upstream (a schema too
  broad is fixed in the schema). Use `Enum.MEMBER as const`, never
  `'literal' as Enum.MEMBER`.
  Values from the URL are strings: parse them. Casting back and forth between
  two types means one of them is wrong. `as unknown as` in test data is a cast
  too. A cast that stays gets a one-line reason.
- **Narrow parameters to what the function uses.** Accept `File[]`, not
  `FileList | File[]`; accept the fields a helper reads, not a bigger object.
- **Derive types, don't re-spell them.** Use the generated type, the library's
  own type (`ComponentProps<typeof Select>['onChange']`, `ButtonProps['size']`;
  in tests too, never a re-declared `Props`) and built-in utilities
  (`NonNullable`, `Pick`).
- **Don't borrow a type for a field that only shares its name.** A client-side
  `status` isn't the API's `status`; declare it separately.
- **Enums for closed sets.** Compare against and store the generated or shared
  enum member, never the raw string or number. Build options from enum values.
  With more than two members, check the one you mean (`=== Status.Active`),
  not `!== Status.Archived`, which quietly admits the others and any added
  later.
- **Exhaustive for sets you own, partial for sets the API owns.** For a
  client-defined enum, type maps as `Record<LocalEnum, T>` and end a `switch`
  with an exhaustiveness check, so adding a member fails the build wherever it
  must be handled. A backend enum can grow, and the API can return a value the
  client doesn't know yet: map it with `Partial<Record<…>>` and a fallback.
- **One status, not overlapping booleans.** Model a lifecycle as one status
  enum or a discriminated union, not `isPaid`, `isPending`, `isOverdue` that can
  contradict each other. Props too: `removing` plus `removed` give four
  combinations for three real states, so take one `state`.
- **One return type per function.** A validator returns a boolean where `true`
  means valid; a getter returns `T | undefined`. Not `string | false`. The
  caller decides how to show absence or errors.
- **Let TS infer what it can:** return types, and `useState('')` rather than
  `useState<string>('')`. Add a generic only when the initial value doesn't
  describe the full type. Use `import type` for types.
- **Name the props type** next to the component, not inline in the parameter
  list, with the repo's choice of `interface` or `type`.
