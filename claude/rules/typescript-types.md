---
paths:
  - "**/*.{ts,tsx}"
---

# Honest types

Types say what the data really is. The schema and the generated types are the
source of truth; bend the code to the types, never the types to the code.

- **Check the generated type before handling absence.** No `?? ''`, `|| 0`,
  `?.` or `x && format(x)` on a value the schema says is always there: the
  fallback hides what the data is and suggests a case that can't happen.
- **Required unless a real caller omits it.** Don't make a prop or field
  optional to skip a check, or because its parent object is optional. A
  nullable schema field is a required `T | null`, not `x?: T`.
- **Narrow, don't cast.** No `as T`, `!` or `@ts-ignore` to quiet the checker.
  Filter nullish items once with a type predicate
  (`items.filter((x): x is Item => x != null)`) and use the narrowed list, or
  fix the type upstream. A cast usually means a type is designed wrong; one
  that stays gets a one-line reason.
- **Narrow parameters to what the function uses.** Accept `File[]`, not
  `FileList | File[]`; accept the fields a helper reads, not a bigger object.
- **Derive types, don't re-spell them.** Use the generated type, the library's
  own type (`ComponentProps<typeof Select>['onChange']`, `ButtonProps['size']`)
  and built-in utilities (`NonNullable`, `Pick`).
- **With GraphQL, type props from fragments, never from the query.** When a
  component needs part of a query result, define a fragment for it instead of
  `Pick<>` chains or `NonNullable<Q['a']['b']>['nodes'][number]`.
- **Don't borrow a type for a field that only shares its name.** A client-side
  `status` isn't the API's `status`; declare it separately.
- **Enums for closed sets.** Compare against and store the generated or shared
  enum member, never the raw string or number. Build options from enum values.
- **Map backend enums partially.** An exhaustive `Record<BackendEnum, T>` breaks
  the build when the enum grows, and the API can return a value the client
  doesn't know yet: use `Partial<Record<…>>` with a fallback.
- **One status, not overlapping booleans.** Model a lifecycle as one status
  enum or a discriminated union, not `isPaid`, `isPending`, `isOverdue` that can
  contradict each other.
- **One return type per function.** A validator returns a boolean where `true`
  means valid; a getter returns `T | undefined`. Not `string | false`. The
  caller decides how to show absence or errors.
- **Let TS infer what it can:** return types, and `useState('')` rather than
  `useState<string>('')`. Add a generic only when the initial value doesn't
  describe the full type. Use `import type` for types.
- **Name the props type** (`interface Props`) next to the component, not inline
  in the parameter list.
