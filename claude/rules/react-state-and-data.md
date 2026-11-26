---
paths:
  - "**/*.{tsx,jsx}"
  - "**/use*.{ts,js}"
---

# React state, effects and data

Where state lives, when effects run, and where data is fetched. The repo's own
rules and neighbouring code win where they differ.

## State and effects

- **One source of truth.** No `useEffect` that copies props or query data into
  state, or pushes a value up with `onXChange(value)`. Derive the value, or
  move the state or query to the component that owns it.
- **React in the handler, not in an effect.** Logic triggered by something
  the code already observes (a click, `onCompleted`, a field change) goes in
  that handler, not in an effect that compares with a previous value.
- **`use*` only when it calls hooks.** A function that calls no React hook is
  a plain service (`getTotal`, `checkHasChanges`); don't wrap a single hook or
  a constant in a new hook.
- **Memoize for a reason:** a stable reference something depends on, or a
  measured cost. Not by default. Static objects, options built from enums and
  stable empty defaults go at module level instead.
- **Honest effect dependencies.** List everything an effect uses instead of
  disabling `exhaustive-deps`. When adding a dependency, check that refetches
  or new identities won't now re-run the effect and change behaviour.
- **Clean up on unmount.** Cancel debounces and pending requests, and release
  resources (object URLs, subscriptions) in the effect cleanup, not on a timer.
- **State has the data's shape:** an array for many items, `T | null` for
  nothing selected, a real initial value instead of a fallback at every read.
- **Per-instance state is per instance.** No stateful class instance at module
  level unless every component instance is meant to share it.
- **Context only for app-wide values that change** (theme, locale, current
  user). Not for static helpers.
- **URL-addressable UI comes from the router.** Drive pagination, tabs and
  open modals from the URL, so shared links work, not from effects.
- **A workaround needs its problem named.** Before adding an effect that
  resets state, a retry wrapper or a reshaping helper, ask whether the source
  can provide the right data or the design can remove the need.

## Forms

- **Form state mirrors the mutation input.** Field names match the input's
  fields, every submitted value is in the initial values, and display-only or
  UI-only values stay out of form state.
- **Let the form library do its job:** it owns input state, validation lives
  in its `validate`, and dependent-field resets are visible on the driving
  field, not hidden in the submit handler. Validate on submit rather than with
  complex cross-field refinements on every change.
- **Make related fields required** rather than disabling one until another is
  filled.

## Data

- **Fetch where the flow starts.** Run a query once in the page or container
  that owns the data and pass results down. Never query inside a shared
  component: it fetches everywhere it's used. Presentational components never
  fetch.
- **Don't serialise independent requests.** A query that waits for another
  without needing its result, or blocks an unrelated section, is a waterfall.
  Don't make parallel requests sequential for convenience.
- **Request only the fields used**, and reuse an existing query or fragment
  before adding a near-copy. Keep a single-use fragment next to its query.
- **Use the client's built-ins** (`networkStatus`, fetch policies,
  `onCompleted`) instead of hand-rolled flags like `isFetched`.
- **Refetch through the owner.** After a mutation, call a `refetch` passed
  from the component that owns the query, in `onCompleted`, rather than a
  conditional `refetchQueries` list that hides which screens are affected.
  Within one feature, use one approach.
- **A hook exposes only what callers use.** Return `useQuery`'s result
  directly rather than rebuilding it.

## Loading, errors and permissions

- **Every query and mutation has its states.** A skeleton on the first load,
  an overlay on refetch, a loading state on the button while a mutation runs,
  and success and error feedback when it's done. Never a blank section.
- **Loading, empty and no-permission are different states.** Don't fold one
  into another, and show an explanation rather than nothing.
- **Handle errors by contract.** Match a backend error code, never message
  text. Route mutation errors through the repo's shared handler. If you turn a
  default error handler off, handle every other error yourself.
- **Permission-gated features render only when their operation is enabled.**
  Handle disabled as well as hidden, and never fall back to a different flow.
