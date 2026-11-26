---
paths:
  - "**/*.{tsx,jsx}"
---

# React components, state and data

Complements `frontend-feature-layers`. These are defaults: when the repo's
rules or the surrounding code clearly do otherwise, follow them and say so.

## Contract

- **The parent decides whether a component renders.** Don't `return null` on a
  missing prop: make the prop required and guard at the call site. (`return null`
  still mounts the component and runs its hooks.)
- **A component knows nothing about where it's used.** No outer margins, no
  domain or mode flags (`isOnboarding`, `isEditMode`), no copy computed from a
  parent's state. Take a `ReactNode` slot, a render prop or plain props instead.
- **Pass only what's rendered**, not a whole query object or class instance.
- **Shared components with several consumers:** a new required prop is a
  breaking change. Check every consumer first.
- **Props that only make sense together** are a discriminated union.
- **Call a hook at the layer where its input exists.** Don't call it with `null`
  and branch inside.

## State and effects

- **One source of truth.** No `useEffect` that copies props or query data into
  state, or pushes state up to a parent. Derive the value, or lift the query to
  the component that orchestrates.
- **React in the handler, not in an effect.** Logic triggered by a change the
  code already observes goes in `onChange` or `onCompleted`.
- **Form state mirrors the mutation input.** A value that isn't submitted lives
  outside the form state.
- **A `use*` function must call hooks.** Otherwise it's a service: a plain
  function the caller can wrap in `useMemo`.
- **Memoize for a reason** (a stable reference something depends on, or real
  cost), not by default. Constants, options built from enums, and static style
  objects go outside the component.

## Data

- **Don't query inside a shared component.** It fetches everywhere the component
  is used. Query once where the flow starts.
- **Don't let one query block unrelated sections, or start only after another
  resolves** (a waterfall). Put each query in the container that needs it.
- **Request only fields that are used.** Reuse an existing query or fragment
  before adding a near-copy.
- **Loading:** a skeleton on the first load, an overlay on refetch, a loading
  state on the button for a pending mutation. Mutations show success and error
  feedback. Match backend errors by code, not message text.
- **Handle every backend state:** disabled and forbidden operations, flag
  combinations, empty lists. Hide a feature rather than show it broken. Show a
  placeholder rather than wrong data.

## Markup

- **Use the design system's components and props** (layout, spacing tokens,
  variants, text) before custom CSS. Don't restate defaults or wrap block
  elements in flex. A style that only fixes the parent's layout belongs in the
  parent.
- **JSX stays declarative.** Compute values before `return`. No nested
  ternaries. Use `Boolean(n) && …` or `n > 0 && …`, never `n && …` (it renders `0`).
- **Inline a component or `renderX()` helper used once** that only adds nesting.
- **Experiments are designed for removal.** Gate them at one point near the top
  (`{enabled && <X />}`). Give each variant its own function rather than passing
  the flag into helpers.
