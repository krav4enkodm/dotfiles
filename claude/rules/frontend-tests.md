---
paths:
  - "**/*.{test,spec,cy}.{ts,tsx,js,jsx}"
  - "**/*.stories.{ts,tsx,js,jsx}"
  - "**/{mocks,__mocks__,fixtures}/**/*.{ts,tsx,js,jsx,json}"
---

# Frontend tests

Follow the repo's testing guide for which runner tests what; these are the
defaults where it says nothing.

- **Test at the right level.** Services and pure functions get unit tests, even
  trivial ones in shared libraries. Components are tested through user
  behaviour in the repo's component-test runner. Don't duplicate coverage
  another level already has; a parent's test doesn't assert its children's
  text or internals.
- **Cover what you added.** Every new component and every branch you add (an
  effect, a reset, each step of a flow, the disabled, empty, error and loading
  states, each state the backend can return) gets a test that sets up that
  exact case. Drive it like a user: click submit, then assert the loading or
  disabled state. A bug fix comes with a test that reproduces the bug; a filter
  or transform gets the case where nothing matches.
- **A test must fail when the behaviour breaks.** Assert what the user sees
  (`toBeVisible()`, the link's `href`, the computed value), not just presence.
  If it stays green with the code removed, fix it.
  - Give every input a distinct value: with `{}` or one shared id everywhere,
    swapped props still pass `toHaveBeenCalledWith`.
  - Pair a negative assertion with a positive one on the same selector: a
    `not.toBeInTheDocument()` stays green after the selector stops matching.
  - Don't assert what a mock returns, or repeat an assertion.
- **Test your code, not the library.** Don't re-check the design system's
  error text, React behaviour or what the type checker guarantees, and don't
  re-implement a third-party component in a mock or mock simple design-system
  primitives. Where the repo has visual snapshots, leave copy and layout to
  them.
- **Select the way a user finds the element:** by role and accessible name,
  then label, then text; a test id only where none of those identify it, or
  where the repo's testing guide says test ids. Scope with `within` rather than
  ids drilled through props. Never select by classes, `id` or a library's
  internal markup.
- **Exact matchers:** `toBe(true)`, not `toBeTruthy()`; `toHaveTextContent`
  matches substrings, so compare exact text with `toBe`.
- **The name is the spec.** Put the condition in `describe('when …')` and the
  outcome in `it`, in user terms ("shows the error message"), not
  implementation terms ("`loading` is `true`", "correct props").
  Parameterised names print their case. When the assertions change, the name
  changes with them.
- **Arrange, act, assert stay separate.** A render helper only renders; mocks
  and setup sit in the test or `beforeEach`, so each test's preconditions are
  visible. Shared fixtures return the plain, successful case; a test that needs
  a failure, an empty result or a flag sets it inline.
- **Typed mocks next to what they mock.** Type mocks and story data with the
  API's generated types, annotated on the fixture itself
  (`const user: User = …`), keep them next to the request they mock, and
  import them instead of building ad-hoc objects with `as` casts. Typed mocks
  stop compiling when the API changes; untyped ones drift silently. Shared
  providers go in one render wrapper.
- **Stories render the real component in a distinct state.** Pass args to the
  actual component, never a rebuilt layout; each story shows a state the others
  don't. Delete stories that look the same.
- **If a story breaks, fix the story's mocks,** never the component with a
  defensive fallback. Don't switch a visual snapshot off because it's flaky
  (freeze the animation, find the cause), and give any skip a one-line reason.
- **Keep helpers minimal:** no parameters only one test passes, no return values
  nobody reads, no providers the component no longer needs, no helper that
  hides a one-line setup. Mount only what the test needs.
