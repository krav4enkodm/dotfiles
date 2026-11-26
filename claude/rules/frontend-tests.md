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
  another level already has.
- **Cover what you added.** Every new component and every branch you add (an
  effect, a reset, each step of a flow, the disabled, empty, error and loading
  states, each state the backend can return) gets a test that sets up that
  exact case. Drive it like a user: click submit, then assert the loading or
  disabled state.
- **A test must fail when the behaviour breaks.** Assert what the user sees
  (`toBeVisible()`, the link's `href`), not just presence. If it stays green
  with the code removed, fix it.
- **Test your code, not the library.** Don't re-check the design system's
  error text, React behaviour or what the type checker guarantees, and don't
  re-implement a third-party component in a mock. Where the repo has visual
  snapshots, leave copy and layout to them.
- **Select by test id,** not copy, classes or `id`: one static test id on the
  element you interact with, reached with `within` and an index rather than ids
  drilled through props.
- **Exact matchers:** `toBe(true)`, not `toBeTruthy()`. Make the test name say
  what it asserts.
- **Typed mocks next to what they mock.** Type mocks and story data with the
  API's generated types, keep them next to the query they mock, and import them
  instead of building ad-hoc objects with `as` casts. Shared providers go in one
  render wrapper.
- **If a story breaks, fix the story's mocks,** never the component with a
  defensive fallback. Don't switch a visual snapshot off because it's flaky
  (freeze the animation, find the cause), and give any skip a one-line reason.
- **Keep helpers minimal:** no parameters only one test passes, no return values
  nobody reads, no providers the component no longer needs. Mount only what the
  test needs.
