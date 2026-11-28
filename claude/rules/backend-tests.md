---
paths:
  - "**/{spec,specs,test,tests}/**/*.{rb,py,go,java,kt,scala,cs,php,ex,exs,rs}"
  - "**/*_{spec,test}.{rb,py,go,exs}"
  - "**/test_*.py"
  - "**/*{Test,Tests,Spec}.{java,kt,scala,cs}"
  - "**/{server,backend,jobs,workers,consumers}/**/*.{test,spec}.{ts,js}"
  - "**/apps/{api,server,backend,worker}*/**/*.{test,spec}.{ts,js}"
  - "**/*.{controller,repository,entity,job,worker,consumer}.{test,spec}.{ts,js}"
---

# Backend tests

Follow the repo's testing guide first; these are the defaults where it says
nothing.

For code that serves requests, runs jobs or owns stored data. In a CLI, a
library or a one-off script, apply only what fits it.

- **Test each behaviour once, at its own layer.** A caller's test asserts it
  called the collaborator with the right arguments; the collaborator's own test
  covers what it does. A parent's test doesn't test its subclasses. API tests
  check the contract, not the business rules behind it.
  - Keep stubs honest: verify them against the real interface, or let the call
    go through, and stub only collaborators whose own tests cover the
    behaviour.
  - When two units share an implicit contract (a field one writes and the
    other reads), add one test that crosses both: tests that each stub the
    other side stay green when it breaks.
- **Cover the risky paths you added:** each new branch, retries, replays,
  cancellation and reschedules, the empty and duplicate cases, and every state
  the code branches on. When the outcome depends on several inputs, test the
  table of combinations. Before changing untested logic, pin its current
  behaviour with a test.
- **A regression gets a test that fails without the fix.** One that stays green
  once the fix is removed is deleted or rewritten.
- **A test must fail when the behaviour breaks.**
  - Expected values are literals, never recomputed with the production code.
  - Compare collections whole, or assert the unwanted items are absent; assert
    order when order is the contract; booleans are exactly true or false.
  - Inputs differ from the defaults and aren't nil or empty: an expected nil
    can't tell working from broken. Set the attribute a case depends on
    explicitly rather than through a factory default.
  - Include a decoy: a record that must not be returned, an email that must
    not be sent.
  - A change assertion states before and after, and the setup makes them
    differ. Prove persistence by reloading.
  - An N+1 or batching test needs at least two parents, each with the
    associations the code reads; with one, the extra query never fires.
  - Assert only the fields the behaviour is about, so unrelated changes don't
    break the test.
- **One baseline, one change per case.** Run the same setup with only the
  variable under test flipped; a negative result ("no error", `false`) proves
  something only next to the identical setup giving the positive one.
- **Exercise the real wiring.** No branches on "am I in a test" in production
  code, and no test that rebuilds its own copy of the production configuration.
- **Keep setup minimal.** Build only the records the scenario needs, in memory
  when nothing reads them from the database. Defaults and derived fields live
  in factories or fixtures, not repeated in each test; no helper that hides a
  one-line setup.
- **Shared setup is read-only.** Fixtures created once per file or suite are
  never changed or deleted by a test: the next test breaks depending on run
  order.
- **Deterministic data only:** no random picks of values or orders; write one
  test per case instead.
- **Mirror the code:** one test file per unit, named after it, and the test
  name says what it asserts.
- **Remove what removed code orphaned:** shared test helpers, mocks, fixtures.
