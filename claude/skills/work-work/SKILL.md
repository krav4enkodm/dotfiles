---
name: work-work
description: Implement one or more ready tickets end to end, each in its own herdr worktree. Starts a separate Claude worker per ticket (own context window), runs the tickets in parallel, validates each result against its ticket with an independent validator subagent, sends gaps back for fixing, then has each worker open a draft PR and record demo media. Use when the user asks to work on, implement, or ship tickets that are ready (usually ones produced by work-plan). Not for planning or for tickets that aren't ready.
argument-hint: "<ticket id or path> [<ticket id or path> ...] [--base <branch>]"
disable-model-invocation: true
---

# Work tickets to draft PRs

## The process this skill belongs to

```
work-plan  →  tickets that meet the Definition of Ready
work-work  →  per ticket: worker implements → validator checks → draft PR + demo media, all tickets in parallel
human      →  reviews the draft PRs; iterates through the worker panes or PR comments; marks them ready
```

The ticket is the contract between the steps. The validator checks the code against the ticket, so a vague ticket can't be validated. If a ticket doesn't meet [the Definition of Ready](../work-plan/references/definition-of-ready.md), don't start it and suggest running `work-plan` on it first. The other tickets in the batch can still go ahead.

A ticket is done when the validator returns PASS on the final diff and its worker has finished the brief's Finish step: a draft PR, plus local paths to the demo media. The batch is done when every ticket is done or stopped.

## What is fixed and what is discovered

**Fixed (the user's local setup, every project):** Claude Code, herdr for worktrees and agent panes, and GitHub with the `gh` CLI for PRs. Check `test "${HERDR_ENV:-}" = 1`. If the check fails, say this skill must run inside herdr and stop.

**Discovered per project. Never assume any of these:**

| Concept | How to find it |
|---|---|
| Ticket | [trackers.md](../work-plan/references/trackers.md): a repo ticket skill, then a connected tracker tool (Linear, Jira, GitHub Issues…), then a markdown file path |
| Branch name | The "Branch name" row for the ticket's tracker in [trackers.md](../work-plan/references/trackers.md) |
| Default branch | `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` |
| Checks (test, lint, typecheck, format) | The repo's CLAUDE.md / AGENTS.md / CONTRIBUTING, then the task runner (`package.json` scripts, Makefile, justfile, nx, etc.) |
| Demo tooling | The repo's own demo skill if it has one (it knows the test accounts and data rules), else the global `record-video` skill (`avr` on PATH), else skip. Only for user-visible changes. Always in unattended mode |
| Running the app | The repo's agent instructions and dev scripts: the command that serves the app locally against a shared non-production environment (e.g. a dev server pointed at staging), its URL, and how browser automation gets a session (a saved storage state, a shared one, or a login the user does once). Used for the worker's design check, the validator's running-app check, and the demo. Only one dev server at a time, across the whole batch: see [The app slot](#the-app-slot) |
| Design tool | The ticket's Design section names the source (e.g. a Figma file key). The tools are the design MCP's (`get_design_context`, `get_variable_defs`, `get_screenshot` for Figma) |

Project specifics are discovered once per batch and shared by every ticket in it.

## Workspace

Everything outside the repo lives under `~/work-work/<repo>/`:

```
~/work-work/<repo>/
  batch.md        the batch state table (see "Running several tickets")
  <ticket-id>/
    ticket.md     the ticket as worked: the tracker text plus amendments
    brief.md      what the worker was asked to do
    report.md     what the worker reports back
    media/        screenshots and videos, never committed
```

## Steps

Steps 1–3 prepare every ticket before any worker starts. Steps 4–10 run per ticket, and tickets move through them independently.

1. **Load the tickets.** For each ticket, fetch its full text and save it to `<ticket-id>/ticket.md`. From here on that file is the contract: the worker and the validator always work from it, and every decision made during the work goes into it first (see [Amending the ticket](#amending-the-ticket)). Check it against the Definition of Ready. If it's not ready, drop it from the batch and name the missing parts.
2. **Pick the bases.** Use `--base` if given; with several tickets it applies to all of them. Otherwise, per ticket:
   - **Stacked ticket** (its first line says "Stack n/m"): base on the branch of the ticket at position n−1. For position 1, use `origin/<default branch>`. If ticket n−1's branch doesn't exist yet and n−1 isn't in this batch, stop and say to work the stack from the bottom up. Take the base from the stack position, not from "blocked by" links, which record real dependencies rather than order.
   - **Standalone ticket:** `origin/<default branch>`.

   **Re-check the code claims if the code moved since planning:** the ticket is above position 1 in a stack, or `git log <base> --since=<ticket last updated> -- <paths in its Scope>` shows commits. Run the `readiness-reviewer` in single mode against the base, one agent per ticket, in parallel. Apply what it resolves from the code as amendments, ask the user its questions, and drop the ticket from the batch if it finds a blocker the user doesn't resolve.
3. **Plan the batch** (skip for one ticket). Follow [Running several tickets](#running-several-tickets): order stacked tickets, check for overlapping scope, then write `batch.md`. Discover the project specifics from the table above once. Put the check commands in each brief; the validators get the same list. For a UI ticket, also put "Running the app" and "Design tool" in its brief, and make sure browser automation can get a session before any worker needs it, so a login prompt doesn't block it halfway.
4. **Create the worktree** for each ticket that can start now: `herdr worktree create --cwd <repo> --branch <branch> --base <base> --label "<ticket-id> <title>" --no-focus`. Read the workspace and pane IDs from the JSON response; never guess them. For any other herdr command, check `herdr <group>` for syntax first.
5. **Start the worker:** `herdr agent start <ticket-id-lowercase> --kind claude --pane <root pane>`. Write `brief.md` from [worker-brief.md](references/worker-brief.md), then send `herdr agent prompt <name> "Read <path>/brief.md and follow it."`. Start every ready worker before waiting on any of them.
6. **Wait for the workers.** Run one `herdr agent wait <name>` per worker in the background (Bash `run_in_background`), so you're notified as each one finishes. On each notification, read the last lines of that worker's pane and its `report.md`:
   - `WORK-WORK: DONE` → go to step 7 for that ticket.
   - `WORK-WORK: NEEDS-APP` → queue it for [the app slot](#the-app-slot). When the slot is its turn, tell the worker "The app is yours. Stop it when you're done." and wait again.
   - `WORK-WORK: BLOCKED` → show the user the question exactly as written, prefixed with the ticket id, with a herdr notification (`--sound request`). Write the answer into `ticket.md` as an amendment, then send the worker the answer, tell it `ticket.md` changed, and wait again.
   - **Idle with no marker, or blocked on a permission prompt** → read the pane, tell the user which ticket it is and what it's waiting on, and don't answer approval dialogs for them.

   Any marker after a grant releases that worker's hold on the app slot. Update `batch.md` after every transition.
7. **Validate.** Start the `ticket-validator` agent in the background with the current text of `ticket.md`, the worktree path, the base ref and the check commands. For a UI ticket, add the design tool and file key, and "Running the app" from step 3, and start it only when it holds the app slot. Give it nothing the worker wrote: no report, no summary. It pulls the design and measures the running app itself. Validators for different tickets can run at the same time.
8. **Fix loop.** On FAIL, send the validator's gap list to the worker and go back to step 6 for that ticket. After **2** failed rounds, stop that ticket: notify the user with its remaining gaps and leave its worker running. The rest of the batch carries on.
9. **Finish.** On PASS, prompt the worker with the "Finish" section of the brief: record demo media, then open the draft PR with the media attached. For a user-visible change the demo needs the app, so send Finish only when the ticket holds the app slot. Once a stacked ticket passes, start the next ticket of its stack (steps 4–5), based on this ticket's branch.
10. **Report.** When a ticket's worker reports its PR, send a herdr notification (`--sound done`) and post one line: ticket id and PR link. When the whole batch is done or stopped, reply with one section per ticket:
    - the PR link, or why the ticket stopped;
    - the validator's verdict table, with design rows it couldn't check in the running app listed separately as "not independently checked";
    - the amendments made to the ticket, and confirmation they were written back to the tracker;
    - absolute paths to the files in `media/`;
    - setup items from the ticket that are still open.

Leave the worktrees and the workers running. The user reviews the PRs and iterates through the worker panes.

## Running several tickets

Each ticket gets its own worktree, worker, workspace folder and validator, exactly as for one ticket. The coordinator is the only part shared across them, and it is the scheduler.

- **One stack, one ticket at a time.** Tickets in the same stack don't run in parallel: the higher one would build on code that is still changing. Start the lowest one; start the next when the one below it passes validation (step 9).
- **Overlapping scope.** Compare the Scope sections of the tickets that would run in parallel. If two change the same files, or one's "Done when" relies on another's change, ask the user before starting: run them in sequence (recommended; the second starts when the first passes), or in parallel and accept a merge conflict on the later PR.
- **One question at a time.** When several workers are BLOCKED, ask the user about one ticket at a time, oldest first, each prefixed with its ticket id. Other tickets keep moving while one waits for an answer.
- **One ticket's trouble stays its own.** A blocked, failing or stopped ticket never stops the others.
- **Keep the state in `batch.md`,** so the batch survives a long session and context compaction. One row per ticket: id, branch, base, worker name, pane, state (queued / working / needs-app / blocked / validating / fixing round n / finishing / done / stopped), PR link. Under the table: who holds the app slot and who is queued for it. Re-read it before acting on any notification.

### The app slot

Only one dev server runs at a time, and the browser automation has one session. The coordinator hands that out as a single slot, one holder at a time, first come first served:

- **A worker** asks for it with `WORK-WORK: NEEDS-APP` before starting the app (the design check, any manual check), and gives it back by stopping the app and ending its turn with any marker.
- **A validator for a UI ticket** holds it from the moment you start it until it returns.
- **A worker in Finish** holds it from when you send Finish until it reports done, if the change is user-visible.

If the user's own dev server is already on the port, use it or wait for it; never kill it. With one ticket the slot is always free, so grant it right away.

## Iterating after review

When the user says "address comments on <ticket>" or "change X in <ticket>" (one ticket or several; each runs on its own as in the batch):
1. Sort each request or PR comment (`gh pr view --comments`): a fix inside the ticket as written, or a change to its scope, behaviour or design. Amend `ticket.md` for every change first; otherwise the validator checks against the old contract and fails the change as out of scope.
2. Prompt the worker with the requests, and tell it whether `ticket.md` changed. Wait as in step 6.
3. Validate again (step 7). On FAIL, run the fix loop (step 8).
4. On PASS, prompt the worker to push and, if behaviour changed, to update the PR description with the `open-pr` skill.
5. Write new amendments back to the tracker, then reply with what changed.

## Amending the ticket

An amendment is any decision made after planning: an answer to a BLOCKED question, a change requested in review, or a fix from the re-check in step 2.

- Edit `ticket.md` in place: a changed scope goes in Scope or Out of scope, and the decision itself gets a line under Decisions saying where it came from ("from review", "answer to the worker's question").
- Tell the worker `ticket.md` changed before it continues.
- If the decision also affects another ticket in the batch (a shared contract, a moved piece of scope), amend that ticket too and tell its worker.
- At Report, and after each review round, write the amendments back to the tracker: patch the Decisions and Scope sections per [trackers.md](../work-plan/references/trackers.md), or edit the markdown ticket file. If the repo has its own ticket skill, follow its rules for edits.

## Rules

- **Never answer an approval dialog or a question for the user.** Relay it exactly as it appears, with its ticket id.
- **Writing amendments back is the only ticket edit.** No status, assignee or priority changes unless the repo's ticket skill says to.
- **Never close a worktree, pane or workspace.** Cleanup after merge is the user's call.
- **Never copy production data into briefs, tests, or demos.** Tests use synthetic data; demos use the shared non-production environment's existing data, read-only.
