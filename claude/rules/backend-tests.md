---
paths:
  - "**/{spec,specs,test,tests}/**/*.{rb,py,go,java,kt,scala,cs,php,ex,exs,rs}"
  - "**/*_{spec,test}.{rb,py,go,exs}"
  - "**/test_*.py"
  - "**/*{Test,Tests,Spec}.{java,kt,scala,cs}"
  - "**/{server,backend,api,services}/**/*.{test,spec}.{ts,js}"
---

# Backend tests

Follow the repo's testing guide first; these are the defaults where it says
nothing.

- **Test each behaviour once, at its own layer.** A caller's test asserts it
  called the collaborator with the right arguments; the collaborator's own test
  covers what it does. A parent's test doesn't test its subclasses. API tests
  check the contract, not the business rules behind it.
- **Cover the risky paths you added:** each new branch, retries, replays,
  cancellation and reschedules, the empty and duplicate cases, and every state
  the code branches on.
- **A regression gets a test that fails without the fix.**
- **A test must fail when the behaviour breaks.** Watch for assertions that
  can't fail, fixtures that can't represent the case that differs, and a new
  test asserting the opposite of an existing one.
- **Exercise the real wiring.** No branches on "am I in a test" in production
  code, and no test that rebuilds its own copy of the production configuration.
- **Keep setup minimal.** Build only the records the scenario needs, in memory
  when nothing reads them from the database. Defaults and derived fields live
  in factories or fixtures, not repeated in each test; no helper that hides a
  one-line setup.
- **Deterministic data only:** no random picks of values or orders; write one
  test per case instead.
- **Mirror the code:** one test file per unit, named after it, and the test
  name says what it asserts.
- **Remove what removed code orphaned:** shared examples, mocks, fixtures.
