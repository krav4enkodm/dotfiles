# Worker brief template

The orchestrator fills this in and writes it to `~/work-work/<repo>/<ticket-id>/brief.md`. Keep it to facts the worker can't cheaply find itself.

```markdown
# <ticket-id>: <title>

You are implementing one ticket in this worktree: <worktree path>
Branch: <branch>, based on <base>. Another session coordinates you and validates your work against the ticket.

## Ticket

The ticket is `<workspace>/ticket.md`. Read it first: it is the contract you're validated against. When a decision is made during the work, the coordinator writes it into that file and tells you; re-read it then.

## Project specifics

- Checks: <test / lint / typecheck / format commands, scoped to affected code where the repo supports it>
- Running the app: <how to start it locally against a shared non-production environment, its URL, and how the browser automation logs in; "n/a" for non-UI work>
- Design tool: <e.g. the Figma MCP tools and the file key; "n/a" for non-UI work>

## How to work

1. Read the repo's agent instructions (CLAUDE.md, AGENTS.md, rule files) before you write code, including any constraints on running things locally.
2. Turn each "Done when" item into a test that fails first, where it can be tested automatically. Then implement until those tests pass.
3. Stay inside the ticket's Scope. Anything in "Out of scope" belongs to another ticket, even if fixing it looks easy.
4. Run the checks listed above until they pass.
5. **Design check** (only if the ticket has a Design section). Pull values from the design, never from memory or the ticket text:
   - For each element in the Design section, pull its node with the design tool (variables/tokens and what they resolve to, plus the structure and a screenshot). Read the ticket's notes on states first: a node drawn as hover, active or open is not the resting look.
   - Implement each value through the design-system prop or token that produces it, not a hardcoded value. Check the component's defaults in the installed source (font size, title case, margins between siblings); they often differ from the design.
   - Start the app as described under "Running the app" and measure each element's computed styles in it: every property the node's variables cover (typography: size, weight, line height, case; colour and background per state; size; spacing to neighbours). Check each state the ticket names (rest, hover, open, disabled).
   - Where a value can be asserted cheaply, add it to the component's test (e.g. computed font size), so CI guards it.
   - A mismatch you can't fix inside the Scope, or a design question the ticket doesn't answer, goes to `report.md` as a question; end with `WORK-WORK: BLOCKED`.
   - Stop the app when you're done.
6. Commit on this branch with the `commit` skill if it's installed, otherwise following the repo's commit conventions. Don't push yet.
7. Write `<workspace>/report.md`:
   - each "Done when" item, and how it's met (test name or `path:line`);
   - for UI tickets, the design table: element · property · design variable and value · prop/token used · measured value in the running app · match;
   - decisions you made that the ticket didn't specify;
   - anything you couldn't do, and why.
8. End your turn with the line `WORK-WORK: DONE`.

If something needs a decision the ticket and code don't answer, don't guess. Write the question in `report.md` with your recommended option, and end your turn with `WORK-WORK: BLOCKED`.

## Finish (only when the coordinator tells you validation passed)

1. Open the PR with the `open-pr` skill against `<base>`. It creates a draft and handles stacks. Put the validator's verdict table in the description's testing section, and list design rows the validator couldn't check in the running app as not independently checked. If the repo's template has no section like that, add it at the end under a "Validation" heading. List the ticket's Setup checklist (secrets, infra, flags, backfills) and any manual checks in a named environment in the notes section as still to do; never perform them yourself.
2. If the change is user-visible, record demo media with <demo tooling> from the app running locally against the shared non-production environment (see "Running the app"), showing the real flow end to end. A Storybook or component-test recording is not a demo. Use that environment's existing data only; don't create or change records. Stop the app afterwards. Save the media to `<workspace>/media/` and never commit it.
3. Append the PR link and the media paths to `report.md`, then end your turn with `WORK-WORK: DONE`.
```
