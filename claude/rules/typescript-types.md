---
paths:
  - "**/*.{ts,tsx}"
---

# Honest types

Types say what the data really is. The schema and the generated types are the
source of truth; bend the code to the types, never the types to the code. The
repo's own rules win where they differ.

- **Check the generated type before handling absence.** No `?? ''`, `|| 0`,
  `?.` or `x && format(x)` on a value the schema says is always there: the
  fallback hides what the data is and suggests a case that can't happen.
- **Required unless a real caller omits it.** Don't mark a prop or field
  optional to skip a check. If the parent object is present, its inner fields
  are required. A nullable schema field is a required `T | null`, not `x?: T`.
- **Narrow, don't cast.** No `as T`, `!` or `@ts-ignore` to quiet the checker.
  Filter nullish items once with a type predicate
  (`items.filter((x): x is Item => x != null)`) and use the narrowed list, or
  fix the type upstream. A needed cast usually means a parameter type is wrong;
  one that stays gets a one-line reason.
- **Narrow parameters to what the function uses.** Accept `File[]`, not
  `FileList | File[]`; accept the two fields a helper reads, not the whole
  object. Don't add runtime checks the types already rule out.
- **Derive types, don't re-spell them.** Use the generated fragment or query
  type, the library's own type (`ComponentProps<typeof Select>['onChange']`,
  `ButtonProps['size']`) and built-in utilities (`NonNullable`, `Pick`). When a
  component needs a large part of a query result, add a GraphQL fragment
  instead of a long `Pick<>` or `NonNullable<Q['a']['b']>['nodes'][number]`.
- **Don't borrow a type for a field that only shares its name.** A client-side
  `status` isn't the API's `status`; declare it separately.
- **Enums for closed sets.** Compare against and store the generated or shared
  enum member, never the raw string or number. Build options from enum values.
- **No exhaustive `Record<BackendEnum, T>`.** The backend can add a value and
  break the build; use a partial map with a fallback.
- **One status, not overlapping booleans.** Model a lifecycle as one status
  enum or a discriminated union, not `isPaid`, `isPending`, `isOverdue` that
  can contradict each other.
- **Modes are discriminated unions.** Props that only make sense together, or
  a visual mode, are `{ variant: 'compact' } | { variant: 'media'; src: string }`,
  not a bag of optional fields or a free `className` override.
- **One return type per function.** A validator returns a boolean where `true`
  means valid; a getter returns `T | undefined`. Not `string | false`. The
  caller decides how to show absence or errors.
- **Let TS infer what it can:** return types, and `useState('')` rather than
  `useState<string>('')`. Add a generic only when the initial value doesn't
  describe the full type. Use `import type` for types.
- **Name the props type** (`interface Props` or `type XProps`) next to the
  component, not inline in the parameter list.
