---
name: work-work
description: Implement a plan or a set of ready tickets end to end, each ticket in its own herdr worktree. Starts a separate Claude worker per ticket (own context window) and runs every ticket in parallel as soon as its blockers allow, validates each result against its ticket and against the coding rules with two independent reviewer subagents, sends gaps back for fixing, then has each worker open a draft PR and record demo media. Use when the user asks to work on, implement, or ship a plan or tickets that are ready (usually produced by work-plan). Not for planning or for tickets that aren't ready.
argument-hint: "<plan container or folder | ticket id or path ...> [--base <branch>]"
disable-model-invocation: true
---

# Work tickets to draft PRs

## The process this skill belongs to

```
work-plan  →  tickets that meet the Definition of Ready, linked into waves
work-work  →  per ticket, as soon as its blockers allow: worker implements → validator + rules reviewer check → draft PR + demo media
human      →  reviews the draft PRs; iterates through the worker panes or PR comments; marks them ready and merges
```

The ticket is the contract between the steps. The validator checks the code against the ticket, so a vague ticket can't be validated. If a ticket doesn't meet [the Definition of Ready](../work-plan/references/definition-of-ready.md), don't start it, and suggest running `work-plan` on it first. Tickets that don't depend on it can still go ahead.

A ticket is done when the validator and the rules reviewer both return PASS on the final diff and its worker has finished the brief's Finish step: a draft PR, plus local paths to the demo media. The run is done when every ticket is done or stopped.

## What is fixed and what is discovered

**Fixed (the user's local setup, every project):** Claude Code, herdr for worktrees and agent panes, and GitHub with the `gh` CLI for PRs. Check `test "${HERDR_ENV:-}" = 1`. If the check fails, say this skill must run inside herdr and stop.

**Discovered per project, once per run. Never assume any of these:**

| Concept | How to find it |
|---|---|
| Tickets and links | [trackers.md](../work-plan/references/trackers.md): a repo ticket skill, then a connected tracker tool (Linear, Jira, GitHub Issues…), then markdown files. For a plan, the "Tickets in a plan" and "Wave table" rows |
| Branch name | The "Branch name" row for the ticket's tracker in [trackers.md](../work-plan/references/trackers.md) |
| Default branch | `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` |
| Checks (test, lint, typecheck, format) | The repo's CLAUDE.md / AGENTS.md / CONTRIBUTING, then the task runner (`package.json` scripts, Makefile, justfile, nx, etc.) |
| Demo tooling | The repo's own demo skill if it has one (it knows the test accounts and data rules), else the global `record-video` skill (`avr` on PATH), else skip. Only for user-visible changes. Always in unattended mode |
| Running the app | The repo's agent instructions and dev scripts: the command that serves the app locally against a shared non-production environment (e.g. a dev server pointed at staging), its URL, and how browser automation gets a session (a saved storage state, a shared one, or a login the user does once). Used for the worker's design check, the validator's running-app check, and the demo. Also whether it can run once per worktree: see [Dev servers](#dev-servers) |
| Design tool | The ticket's Design section names the source (e.g. a Figma file key). The tools are the design MCP's (`get_design_context`, `get_variable_defs`, `get_screenshot` for Figma) |

## Workspace

Everything outside the repo lives under `~/work-work/<repo>/`:

```
~/work-work/<repo>/
  batch.md        the run's state (see "Running a plan")
  <ticket-id>/
    ticket.md     the ticket as worked: the tracker text plus amendments
    brief.md      what the worker was asked to do
    report.md     what the worker reports back
    media/        screenshots and videos, never committed
```

## Steps

Steps 1–3 prepare the run. Steps 4–10 run per ticket, and each ticket moves through them on its own, as soon as its start gate opens.

1. **Load the tickets.** For a plan, load every ticket in its container (or folder) and its blocked-by links; for ticket ids, load those tickets and their links. Save each ticket's full text to `<ticket-id>/ticket.md`. From here on that file is the contract: the worker and the validator always work from it, and every decision made during the work goes into it first (see [Amending the ticket](#amending-the-ticket)). Then:
   - A ticket whose PR has already merged counts as merged; one whose branch already has an open PR, from an earlier run, ask whether to treat it as passed.
   - Check each remaining ticket against the Definition of Ready. If it's not ready, leave it out and name the missing parts; the tickets that depend on it are left out too.
   - A blocker outside the run must already be merged. If it isn't, leave the ticket out and say which blocker it waits for.
2. **Work out the start gates** from the links (see [Start gates](#start-gates)), and write `batch.md`. For ticket ids not from one plan, compare the Scope sections of tickets that would run at the same time. If two change the same files, or one's "Done when" relies on another's change, ask the user: run them in sequence (recommended; the second gets a blocked-by on the first), or in parallel and accept a merge conflict on the later PR. A plan from `work-plan` has already been checked for this.
3. **Discover the project specifics** from the table above, including [Dev servers](#dev-servers). Put the check commands in each brief; the validators get the same list. For a UI ticket, also put "Running the app" and "Design tool" in its brief. Before starting any UI worker, check the environment once and ask the user for everything missing in one message: the browser automation answers, its session is logged in, the app serves a page, and a production build passes if a Done-when item needs one. Check the browser and session again before handing out the app slot: it may have closed since, and a worker that finds it down halfway is blocked.
4. **Re-check and create the worktree** for each ticket whose gate is open. Re-check its code claims if the code moved since planning: it starts on a blocker's branch, or `git log <base> --since=<ticket last updated> -- <paths in its Scope>` shows commits. Run the `readiness-reviewer` in single mode against the base, in parallel across tickets. Apply what it resolves from the code as amendments, ask the user its questions, and stop the ticket if it finds a blocker the user doesn't resolve. Then: `herdr worktree create --cwd <repo> --branch <branch> --base <base> --label "<ticket-id> <title>" --no-focus`. Read the workspace and pane IDs from the JSON response; never guess them. For any other herdr command, check `herdr <group>` for syntax first.
5. **Start the worker:** `herdr agent start <ticket-id-lowercase> --kind claude --pane <root pane> -- --name "<ticket-id> <title>"`. The name is what the session is listed as in Remote Control on the phone and web. Write `brief.md` from [worker-brief.md](references/worker-brief.md), then send `herdr agent prompt <name> "Read <path>/brief.md and follow it."`. Start every ticket whose gate is open before waiting on any of them.
6. **Wait for the workers.** Run one `herdr agent wait <name>` per worker in the background (Bash `run_in_background`), so you're notified as each one finishes. On each notification, re-read `batch.md`, then the last lines of that worker's pane and its `report.md`:
   - `WORK-WORK: DONE` → go to step 7 for that ticket.
   - `WORK-WORK: NEEDS-APP` (single app slot only) → queue it for the slot. When it's its turn, tell the worker "The app is yours. Stop it when you're done." and wait again. Any later marker releases the slot.
   - `WORK-WORK: BLOCKED` → show the user the question exactly as written, prefixed with the ticket id, with a herdr notification (`--sound request`). Ask about one ticket at a time, oldest first. Write the answer into `ticket.md` as an amendment, then send the worker the answer, tell it `ticket.md` changed, and wait again. If the answer changes the plan itself, see [Changing the plan mid-run](#changing-the-plan-mid-run).
   - **Idle with no marker, or blocked on a permission prompt** → read the pane, tell the user which ticket it is and what it's waiting on, and don't answer approval dialogs for them.

   Update `batch.md` after every transition, and post its table in a few lines (ticket, state, PR), so the user never has to ask how it's going.
7. **Validate.** Start two independent agents in the background, side by side, and give neither of them anything the worker wrote: no report, no summary.
   - **`ticket-validator`**: does the branch implement the ticket? Give it the current text of `ticket.md`, the worktree path, the base ref and the check commands. For a UI ticket, add the design tool and file key, and how to reach the ticket's running app (see [Dev servers](#dev-servers)). It pulls the design and measures the running app itself. Validators for non-UI tickets run side by side; UI validators take turns, because they share this session's browser.
   - **`rules-reviewer`**: does the changed code follow the coding rules that apply to it (the user's and the repo's CLAUDE.md, AGENTS.md and rule files)? Give it the worktree path, the base ref, and the ticket's Scope and Out of scope. Not the list of rules: it finds them from the changed files itself. It needs no browser, so it never waits for the app slot.

   The ticket passes this step when both return PASS. The rules reviewer's notes and conflicts never block; keep them for the PR and the Report.
8. **Fix loop.** On FAIL from either agent, send the worker one message with both gap lists, each under its own heading, and go back to step 6 for that ticket. Every round reruns both agents, since a fix for one can break the other. If a rules violation can only be fixed outside the ticket's Scope, or the ticket itself requires what a rule forbids, don't send it to the worker: ask the user, and amend `ticket.md` with the answer. After **2** failed rounds, stop the ticket: notify the user with its remaining gaps and leave its worker running. Every ticket that depends on it, directly or not, is stopped too. The rest of the run carries on.
9. **Finish.** On PASS from both, prompt the worker with the "Finish" section of the brief, including the rules reviewer's notes if it had any: record demo media, then open the draft PR with the media attached. Then open the gates this PASS unlocks (see [Start gates](#start-gates)) and go to step 4 for those tickets.
10. **Report.** When a ticket's worker reports its PR, send a herdr notification (`--sound done`) and post one line: ticket id and PR link. When the whole run is done or stopped, reply with the final wave table (ticket, PR or why it stopped), then one section per ticket:
    - the validator's verdict table, with design rows it couldn't check in the running app listed separately as "not independently checked";
    - the rules reviewer's notes and conflicts, if any;
    - the amendments made to the ticket, and confirmation they were written back to the tracker;
    - absolute paths to the files in `media/`;
    - setup items from the ticket that are still open.

    If tickets are still waiting on merges when everything else is done, say which merges they wait for, and leave the merge watch running.

Leave the worktrees and the workers running. The user reviews the PRs and iterates through the worker panes.

## Running a plan

Each ticket gets its own worktree, worker, workspace folder and validator. The coordinator is the only part shared across them, and it is the scheduler. There is no limit on how many tickets run at once: the links decide.

### Start gates

Count a ticket's **open blockers**: blockers in the run whose PR hasn't merged.

| Open blockers | Starts when | Base |
|---|---|---|
| None | Right away | `--base` if given, else `origin/<default branch>` (fetch first) |
| One | That blocker passes validation | The blocker's branch |
| Two or more | All but one have merged, and the last one has passed | The last open blocker's branch |

A chain of single-blocker tickets becomes a `gh stack` when each worker opens its PR with `open-pr`. Tickets from before waves existed, with "Stack n/m" on the first line, are blocked by the ticket at position n−1.

**Watching for merges.** Merges aren't notified. While any ticket waits on one, keep one background loop running that checks the blockers' PRs every 5 minutes (`gh pr view <branch> --json state -q .state`) and exits when one merges. On exit, open the gates it unlocks, start the loop again if others are still waiting, and rebase the dependents already built on the merged branch (see [Rebasing dependents](#rebasing-dependents)).

### Rebasing dependents

A dependent started on its blocker's branch. When that branch changes after the dependent started, the dependent has to follow:

- **The blocker changed after review** (it passed validation again): tell each dependent's worker to rebase onto the updated blocker branch.
- **The blocker merged:** tell each dependent's worker to rebase onto the default branch: `git fetch && git rebase --onto origin/<default branch> <blocker's last commit> <branch>`. Its base becomes the default branch, or the next open blocker for a fan-in ticket.

Then the worker reruns the checks, and the dependent is validated again (step 7, against its new base). A worker that can't resolve a conflict inside its own Scope ends with `WORK-WORK: BLOCKED`. Its own dependents follow in turn, once it passes again.

### Changing the plan mid-run

An amendment can change the plan itself: a ticket turns out to need a new blocker, or the work needs a new ticket. Then:
1. Pause the tickets downstream of the change: don't start them, and tell their workers to hold. The rest of the run carries on.
2. Propose the change to the user: the new link, or a new ticket drafted with the template in [definition-of-ready.md](../work-plan/references/definition-of-ready.md), with its wave.
3. On their OK, create the ticket or link in the tracker, update the plan's wave table and `batch.md`, and resume the paused tickets under their new gates.

### Dev servers

Running several UI tickets at once needs the app running more than once.

- **One per worktree,** when the repo's dev command takes a port (a `PORT` variable, a `--port` flag) and nothing ties the app to one URL: an auth callback, a CORS allowlist, a cookie bound to a port. Give each UI ticket its own free port (check with `ss -ltn`), and record it in its brief and in `batch.md`. Each worker starts and stops its own server; its validator and demo use that port.
- **A single app slot** otherwise, or when you can't tell. The coordinator hands the app to one holder at a time, first come first served: a worker asks with `WORK-WORK: NEEDS-APP` and gives it back by stopping the app and ending its turn; a UI validator holds it while it runs; a worker in Finish holds it from when you send Finish until it reports done, if the change is user-visible.

Either way, every session drives the same browser, so each agent opens its own tab and works only in tabs it opened. If the user's own dev server is already on a port, use it or pick another port; never kill it.

### Keeping track

- **`batch.md`** keeps the run alive across a long session and context compaction. One row per ticket: id, wave, blocked by, branch, base, worker name, pane, port, state (waiting / working / needs-app / blocked / validating / fixing round n / finishing / done / stopped / paused), PR link. Under the table: who holds the app slot and who's queued, and which merges are being watched. Re-read it before acting on any notification.
- **One ticket's trouble stays its own.** A blocked, failing or stopped ticket only holds up the tickets that depend on it.

## Iterating after review

When the user says "address comments on <ticket>" or "change X in <ticket>" (one ticket or several; each runs on its own):
1. Sort each request or PR comment (`gh pr view --comments`): a fix inside the ticket as written, or a change to its scope, behaviour or design. Amend `ticket.md` for every change first; otherwise the validator checks against the old contract and fails the change as out of scope.
2. Prompt the worker with the requests, and tell it whether `ticket.md` changed. Wait as in step 6.
3. Validate again with both agents (step 7). On FAIL, run the fix loop (step 8).
4. On PASS, prompt the worker to push and, if behaviour changed, to update the PR description with the `open-pr` skill. Then rebase its dependents (see [Rebasing dependents](#rebasing-dependents)).
5. Write new amendments back to the tracker, then reply with what changed.

## Amending the ticket

An amendment is any decision made after planning: an answer to a BLOCKED question, a change requested in review, or a fix from the re-check in step 4.

- Edit `ticket.md` in place: a changed scope goes in Scope or Out of scope, and the decision itself gets a line under Decisions saying where it came from ("from review", "answer to the worker's question").
- Tell the worker `ticket.md` changed before it continues.
- If the decision also affects another ticket in the run (a shared contract, a moved piece of scope), amend that ticket too and tell its worker.
- At Report, and after each review round, write the amendments back to the tracker: patch the Decisions and Scope sections per [trackers.md](../work-plan/references/trackers.md), or edit the markdown ticket file. If the repo has its own ticket skill, follow its rules for edits.

## Rules

- **Never answer an approval dialog or a question for the user.** Relay it exactly as it appears, with its ticket id.
- **Start every message to a worker with `Coordinator:`**, except the first one ("Read <path>/brief.md and follow it."). herdr types into the same pane as the user, so this is how the pane's history tells the run's messages from the user's.
- **Writing amendments back is the only ticket edit**, besides the plan changes the user approves. No status, assignee or priority changes unless the repo's ticket skill says to.
- **Never merge a PR or mark it ready.** Merges are the user's; the run waits for them.
- **Never close a worktree, pane or workspace.** Cleanup after merge is the user's call.
- **Never copy production data into briefs, tests, or demos.** Tests use synthetic data; demos use the shared non-production environment's existing data, read-only.
