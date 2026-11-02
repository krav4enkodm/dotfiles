# Definition of Done

The counterpart of plan-work's Definition of Ready. A ticket is done when all of these hold:

- [ ] **Every "Done when" item is met**, with evidence: a test name, or `path:line` for anything that can't be tested automatically.
- [ ] **Nothing out of scope:** every changed line traces back to the ticket's Scope. No drive-by refactors.
- [ ] **The repo's checks pass** for the affected code: tests, lint, typecheck, format.
- [ ] **The validator returned PASS** on the final diff, not on an earlier round.
- [ ] **A draft PR is open** against the right base, with a description a reviewer can read in two minutes and the validator's verdict table.
- [ ] **Demo media exists** for user-visible changes, recorded on synthetic data and stored locally, not committed.
- [ ] **Setup items** (secrets, infra, flags, backfills) from the ticket are listed in the PR as still to do. The agent never performs them.

Manual checks in a named environment (staging, production) stay with the user. The PR lists them; the validator doesn't claim them.
