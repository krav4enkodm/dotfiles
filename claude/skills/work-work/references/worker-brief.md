# Worker brief template

The orchestrator fills this in and writes it to `~/work-work/<repo>/<ticket-id>/brief.md`. Keep it to facts the worker can't cheaply find itself.

```markdown
# <ticket-id>: <title>

You are implementing one ticket in this worktree: <worktree path>
Branch: <branch>, based on <base>. Another session coordinates you and validates your work against the ticket.

## Ticket

<full ticket text, verbatim>

## Project specifics

- Checks: <test / lint / typecheck / format commands, scoped to affected code where the repo supports it>
- Caveats: <local-run constraints, e.g. "don't start docker compose here; use the shared Postgres">

## How to work

1. Read the repo's agent instructions (CLAUDE.md, AGENTS.md, rule files) before you write code.
2. Turn each "Done when" item into a test that fails first, where it can be tested automatically. Then implement until those tests pass.
3. Stay inside the ticket's Scope. Anything in "Out of scope" belongs to another ticket, even if fixing it looks easy.
4. Run the checks listed above until they pass.
5. Commit on this branch, following the repo's commit conventions. Don't push yet.
6. Write `<workspace>/report.md`:
   - each "Done when" item, and how it's met (test name or `path:line`);
   - decisions you made that the ticket didn't specify;
   - anything you couldn't do, and why.
7. End your turn with the line `WORK-WORK: DONE`.

If something needs a decision the ticket and code don't answer, don't guess. Write the question in `report.md` with your recommended option, and end your turn with `WORK-WORK: BLOCKED`.

## Finish (only when the coordinator tells you validation passed)

1. Push the branch and open a **draft** PR against `<base>`. Use the `open-pr` skill in **pre-approved mode**: the user has pre-approved publishing as a draft, so don't stop to ask for confirmation. If `<base>` is a branch in a `gh stack`, `open-pr` publishes through the stack. Put the validator's verdict table in the description's testing section. If the repo's template has no section like that, add it at the end under a "Validation" heading. List the ticket's Setup checklist (secrets, infra, flags, backfills) in the notes section as still to do.
2. If the change is user-visible, record demo media with <demo tooling>, using seeded or synthetic test data only. Save it to `<workspace>/media/` and never commit it.
3. Append the PR link and the media paths to `report.md`, then end your turn with `WORK-WORK: DONE`.
```
