---
paths:
  - "**/*.{test,spec,cy}.{ts,tsx,js,jsx}"
  - "**/*.stories.{ts,tsx}"
  - "**/{mocks,__mocks__}/**"
---

# Frontend tests

Follow the repo's testing guidelines for which runner tests what. These are
the defaults when it doesn't say.

- **Test at the right level.** Pure functions and services get unit tests.
  Components are tested through user behaviour in the repo's component-test
  runner. Shared libraries are tested even when trivial.
- **Don't retest what's covered elsewhere:** the design system, the framework,
  third-party internals, what the type checker guarantees, and copy covered by
  visual snapshots.
- **Cover the branches users hit:** interactions, every step of a flow, effect
  branches, and disabled, empty and error states. New conditional UI gets a story.
- **Select by test id or role, not copy or CSS.** Assert exactly: `toBe(true)`,
  not `toBeTruthy()`. Prefer `toBeVisible()` when presence alone could pass
  falsely. Make the test name match the assertion.
- **Check that the test fails without the change.** A test still green after
  the code it covers is removed is a false positive.
- **Mocks use the real generated types** and are shared, so tests need no casts.
- **A skipped test, or a visual snapshot switched off, needs a one-line reason**
  in a comment.
- **Mount only what the test needs.** Slow browser tests cost everyone CI time.
