---
paths:
  - "**/*.{tsx,jsx}"
  - "**/use[A-Z]*.{ts,js}"
---

# React state, effects and data

## State and effects

- **One source of truth.** No `useEffect` that copies props or query data into
  state, keeps a dependent field in sync, or pushes a value up with
  `onXChange(value)`. Derive the value, or move the state or query to the
  component that owns it.
- **React in the handler, not in an effect.** Logic triggered by something the
  code already observes (a click, a mutation's success callback, a field
  change, the submit) goes in that handler. Effects are for syncing with
  something outside React, such as a third-party API.
- **`use*` only when it calls hooks.** A function that calls no React hook is a
  plain function (`getTotal`), and a hook that only forwards another hook is
  inlined.
- **`memo`, `useMemo` and `useCallback` solve a real problem:** a measured
  performance issue, or a reference that must stay stable for correctness (a
  derived array or object passed to a memoised child or used in another hook's
  dependencies, a function in an effect's dependencies, a third-party component
  that forbids changing a callback). Not by default: `memo` on a leaf forces
  every caller to wrap its handlers. Static values and helpers that use nothing
  from the component go at module level; `useMemo` with no dependencies is a
  module constant.
- **List every effect dependency.** An effect meant to run once (a third-party
  setup) may disable the rule, with a reason. An effect that keeps two values in
  sync means two sources of truth: fix that instead. When adding a dependency,
  check the effect doesn't now run more often.
- **Clean up on unmount.** Cancel debounces and pending requests, and release
  resources (object URLs, subscriptions) in the effect cleanup, not on a timer.
- **State has the data's shape:** an array for many items, `T | null` for
  nothing selected, a real initial value instead of a fallback at every read.
- **Per-instance state is per instance.** No stateful class instance at module
  level unless every component instance is meant to share it.
- **Props for a level or two, context for a subtree.** Use context when many
  levels share a value; every change re-renders, and can refetch in, every
  consumer. Import static helpers directly.
- **State a shared link should restore** (page, tab, filters, an open detail
  view) **lives in the URL** through the router.

## Forms

- **Form state mirrors the mutation input.** Field names match the input's
  fields, so field errors from the server, where it returns them, land on the
  right field. Every submitted value is in the initial values, a hidden field's
  value is cleared so it isn't submitted, and display-only or UI-only values
  stay out of form state.
- **Let the form library do its job:** it owns input state and validation, and
  a dependent-field reset sits with the field that drives it, not in the submit
  handler.
- **A field that depends on async data shows loading and blocks submit** until
  the data arrives.

## Data

- **Fetch where the flow starts.** Run a query once in the page or container
  that owns the data and pass results down. Never query inside a shared
  component: it fetches everywhere it's used.
- **Don't fetch before the user needs it.** A modal's or drawer's query runs in
  its content, not in the button or hook that opens it; a costly request fires
  only once the user makes the choice that needs it; code behind a flag is
  lazy-loaded.
- **No waterfalls.** A query that waits for another without needing its result,
  or blocks an unrelated section, runs on its own.
- **Request only the fields used**, and reuse an existing request before
  adding a near-copy. A field added to a shared request loads everywhere it's
  used, lists included; when a component starts fetching its own data, remove
  those fields from the parent's request.
- **Use the data client's own status and cache options** instead of hand-rolled
  flags like `isFetched`.
- **Update after a mutation through the narrowest path:** update or invalidate
  only the data the mutation changed, through the data client's own mechanism,
  rather than refetching every screen that might be affected.

## Loading, errors and permissions

- **Every query and mutation shows loading, success and error,** never a blank
  section. Unless the design says otherwise: a skeleton on the first load, an
  overlay on refetch, a loading state on the button while a mutation runs.
  While a query that decides which branch renders (a flag, a permission, a
  required entity) loads, show a skeleton: not `null`, and not the default
  branch.
- **Loading, empty and no-permission are different states.** Don't fold one
  into another, and show an explanation rather than nothing.
- **Match a backend error code, never message text,** and route mutation errors
  through the repo's shared handler. If you turn a default error handler off,
  handle every other error yourself.
- **When the API says an action isn't permitted,** hide or disable it as the
  design says, and never fall back to a different flow.
