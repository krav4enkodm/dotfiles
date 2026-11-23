# Worker brief template

The orchestrator fills this in and writes it to `~/work-work/<repo>/<ticket-id>/brief.md`. Keep it to facts the worker can't cheaply find itself.

```markdown
# <ticket-id>: <title>

You are implementing one ticket in this worktree: <worktree path>
Branch: <branch>, based on <base>. Another session coordinates you and has your work checked against the ticket and against the repo's coding rules.

## Ticket

The ticket is `<workspace>/ticket.md`. Read it first: it is the contract you're validated against. When a decision is made during the work, the coordinator writes it into that file and tells you; re-read it then.

## Project specifics

- Checks: <test / lint / typecheck / format commands, scoped to affected code where the repo supports it>
- Running the app: <how to start it locally against a shared non-production environment, its URL, and how the browser automation logs in; "n/a" for non-UI work>
- App rule: <one of the two below, for UI work; leave out for non-UI work>
  - Own server: "Run the app only on port <port>; other workers use other ports. Stop it when you're done."
  - Shared slot: "Only one dev server runs at a time. Before you start the app for any reason, end your turn with `WORK-WORK: NEEDS-APP` and wait until the coordinator says it's yours. Stop the app when you're done with it."
- Design tool: <e.g. the Figma MCP tools and the file key; "n/a" for non-UI work>

## How to work

1. Read the repo's agent instructions (CLAUDE.md, AGENTS.md, rule files) before you write code, including any constraints on running things locally.
   Other workers run in parallel worktrees. Follow the app rule above, and in the shared browser open your own tab and work only in tabs you opened.
2. Turn each "Done when" item into a test that fails first, where it can be tested automatically. Then implement until those tests pass.
3. Stay inside the ticket's Scope. Anything in "Out of scope" belongs to another ticket, even if fixing it looks easy.
4. Run the checks listed above until they pass.
5. **Design check** (only if the ticket has a Design section): follow "Building" in `~/.claude/skills/work-plan/references/design.md`. Take values from the design, never from memory or the ticket text.
6. Commit on this branch with the `commit` skill if it's installed, otherwise following the repo's commit conventions. Don't push yet.
7. Write `<workspace>/report.md`:
   - each "Done when" item, and how it's met (test name or `path:line`);
   - decisions you made that the ticket didn't specify;
   - anything you couldn't do, and why.
8. End your turn with the line `WORK-WORK: DONE`.

If something needs a decision the ticket and code don't answer, don't guess. Write the question in `report.md` with your recommended option, and end your turn with `WORK-WORK: BLOCKED`.

## Finish (only when the coordinator tells you validation passed)

1. With a shared slot, the coordinator sends this step only when the app is yours, so don't ask for it again. If the change is user-visible, record demo media with <demo tooling> from the app running locally against the shared non-production environment (see "Running the app"), showing the real flow end to end. A Storybook or component-test recording is not a demo. Use that environment's existing data only; don't create or change records. Stop the app afterwards. Save the media to `<workspace>/media/` and never commit it.
2. Open the PR with the `open-pr` skill against `<base>`. It creates a draft, handles stacks, and attaches the media you pass it: give it the demo video and any screenshots that show the change. Put the validator's verdict table in the description's testing section, and list design rows the validator couldn't check in the running app as not independently checked. If the coordinator passed on notes from the rules reviewer, list them in the notes section as open for review. If the repo's template has no section like that, add it at the end under a "Validation" heading. List the ticket's Setup checklist (secrets, infra, flags, backfills) and any manual checks in a named environment in the notes section as still to do; never perform them yourself.
3. Append the PR link and the media paths to `report.md`, then end your turn with `WORK-WORK: DONE`.

## Rebase (only when the coordinator asks)

Your branch is built on another ticket's branch, which changed or merged. Run the rebase the coordinator gives you, resolve conflicts inside your Scope, rerun the checks, and push if you've already opened a PR. End your turn with `WORK-WORK: DONE`. If a conflict needs a change outside your Scope, abort the rebase, write the conflict in `report.md`, and end with `WORK-WORK: BLOCKED`.
```
