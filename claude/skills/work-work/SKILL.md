---
name: work-work
description: Implement one ready ticket end to end in its own herdr worktree. Starts a separate Claude worker there (own context window), validates the result against the ticket with an independent validator subagent, sends gaps back for fixing, then has the worker open a draft PR and record demo media. Use when the user asks to work on, implement, or ship a ticket that is ready (usually one produced by plan-work). Not for planning or for tickets that aren't ready.
argument-hint: "<ticket id or path to ticket file> [--base <branch>]"
disable-model-invocation: true
---

# Work a ticket to a draft PR

## The process this skill belongs to

```
plan-work  →  tickets that meet the Definition of Ready
work-work  →  one ticket → worker implements → validator checks → draft PR + demo media
human      →  reviews the draft PR; iterates through the worker pane or PR comments; marks it ready
```

The ticket is the contract between the steps. The validator checks the code against the ticket, so a vague ticket can't be validated. If the ticket doesn't meet [the Definition of Ready](../plan-work/references/definition-of-ready.md), stop and suggest running `plan-work` on it first.

The ticket is done when the validator returns PASS on the final diff and the worker has finished the brief's Finish step: a draft PR, plus local paths to the demo media.

## What is fixed and what is discovered

**Fixed (the user's local setup, every project):** Claude Code, herdr for worktrees and agent panes, and GitHub with the `gh` CLI for PRs. Check `test "${HERDR_ENV:-}" = 1`. If the check fails, say this skill must run inside herdr and stop.

**Discovered per project. Never assume any of these:**

| Concept | How to find it |
|---|---|
| Ticket | [trackers.md](../plan-work/references/trackers.md): a repo ticket skill, then a connected tracker tool (Linear, Jira, GitHub Issues…), then a markdown file path |
| Branch name | The "Branch name" row for the ticket's tracker in [trackers.md](../plan-work/references/trackers.md) |
| Default branch | `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` |
| Checks (test, lint, typecheck, format) | The repo's CLAUDE.md / AGENTS.md / CONTRIBUTING, then the task runner (`package.json` scripts, Makefile, justfile, nx, etc.) |
| Demo tooling | The repo's own demo skill if it has one (it knows the test accounts and data rules), else the global `record-video` skill (`avr` on PATH), else skip. Only for user-visible changes. Always in unattended mode |
| Running the app | The repo's agent instructions and dev scripts: the command that serves the app locally against a shared non-production environment (e.g. a dev server pointed at staging), its URL, and how browser automation gets a session (a saved storage state, a shared one, or a login the user does once). Used for the worker's design check, the validator's running-app check, and the demo. Only one dev server at a time: if one is already running, use it or wait for the port, never kill a process you didn't start |
| Design tool | The ticket's Design section names the source (e.g. a Figma file key). The tools are the design MCP's (`get_design_context`, `get_variable_defs`, `get_screenshot` for Figma) |

## Per-ticket workspace

Everything outside the repo for a ticket lives in one folder:

```
~/work-work/<repo>/<ticket-id>/
  ticket.md     the ticket as worked: the tracker text plus amendments
  brief.md      what the worker was asked to do
  report.md     what the worker reports back
  media/        screenshots and videos, never committed
```

## Steps

1. **Load the ticket.** Fetch its full text and save it to `ticket.md`. From here on that file is the contract: the worker and the validator always work from it, and every decision made during the work goes into it first (see [Amending the ticket](#amending-the-ticket)). Check it against the Definition of Ready. If it's not ready, stop and name the missing parts.
2. **Pick the base.** Use `--base` if given. Otherwise:
   - **Stacked ticket** (its first line says "Stack n/m"): base on the branch of the ticket at position n−1. For position 1, use `origin/<default branch>`. If ticket n−1's branch doesn't exist yet, stop and say to work the stack from the bottom up. Take the base from the stack position, not from "blocked by" links, which record real dependencies rather than order.
   - **Standalone ticket:** `origin/<default branch>`.

   **Re-check the code claims if the code moved since planning:** the ticket is above position 1 in a stack, or `git log <base> --since=<ticket last updated> -- <paths in its Scope>` shows commits. Run the `readiness-reviewer` in single mode against the base. Apply what it resolves from the code as amendments, ask the user its questions, and stop if it finds a blocker the user doesn't resolve.
3. **Discover the project specifics** from the table above. Put the check commands in the brief; the validator gets the same list. For a UI ticket, also put "Running the app" and "Design tool" in the brief, and make sure browser automation can get a session before the worker needs it, so a login prompt doesn't block it halfway.
4. **Create the worktree:** `herdr worktree create --cwd <repo> --branch <branch> --base <base> --label "<ticket-id> <title>" --no-focus`. Read the workspace and pane IDs from the JSON response; never guess them. For any other herdr command, check `herdr <group>` for syntax first.

5. **Start the worker:** `herdr agent start <ticket-id-lowercase> --kind claude --pane <root pane>`. Write `brief.md` from [worker-brief.md](references/worker-brief.md), then send `herdr agent prompt <name> "Read <path>/brief.md and follow it."`.
6. **Wait for the worker.** Run `herdr agent wait <name>` in the background (Bash `run_in_background`) so you're notified when it's done. Then read the last lines of the pane and `report.md`:
   - `WORK-WORK: DONE` → go to step 7.
   - `WORK-WORK: BLOCKED` → show the user the question exactly as written, with a herdr notification (`--sound request`). Write the answer into `ticket.md` as an amendment, then send the worker the answer, tell it `ticket.md` changed, and wait again.
   - **Idle with no marker, or blocked on a permission prompt** → read the pane, tell the user what it's waiting on, and don't answer approval dialogs for them.
7. **Validate.** Start the `ticket-validator` agent with the current text of `ticket.md`, the worktree path, the base ref and the check commands. For a UI ticket, add the design tool and file key, and "Running the app" from step 3. Give it nothing the worker wrote: no report, no summary, no design table. It pulls the design and measures the running app itself.
   Record `git -C <worktree> rev-parse HEAD` and `git -C <worktree> status --porcelain --untracked-files=no` before it starts, and compare them after it returns. If either changed, the validator touched the worktree: discard its verdict and tell the user.
8. **Fix loop.** On FAIL, send the validator's gap list to the worker and go back to step 6. After **2** failed rounds, stop: notify the user with the remaining gaps and leave the worker running.
9. **Finish.** On PASS, prompt the worker with the "Finish" section of the brief: open the draft PR, record demo media.
10. **Report.** Send a herdr notification (`--sound done`). Then reply with:
    - the PR link;
    - the validator's verdict table, with design rows it couldn't check in the running app listed separately as "not independently checked";
    - the amendments made to the ticket, and confirmation they were written back to the tracker;
    - absolute paths to the files in `media/`;
    - setup items from the ticket that are still open.

Leave the worktree and the worker running. The user reviews the PR and iterates through the worker pane.

## Iterating after review

When the user says "address comments on <ticket>" or "change X in <ticket>":
1. Sort each request or PR comment (`gh pr view --comments`): a fix inside the ticket as written, or a change to its scope, behaviour or design. Amend `ticket.md` for every change first; otherwise the validator checks against the old contract and fails the change as out of scope.
2. Prompt the worker with the requests, and tell it whether `ticket.md` changed. Wait as in step 6.
3. Validate again (step 7). On FAIL, run the fix loop (step 8).
4. On PASS, prompt the worker to push and, if behaviour changed, to update the PR description with the `open-pr` skill.
5. Write new amendments back to the tracker, then reply with what changed.

## Amending the ticket

An amendment is any decision made after planning: an answer to a BLOCKED question, a change requested in review, or a fix from the re-check in step 2.

- Edit `ticket.md` in place: a changed scope goes in Scope or Out of scope, and the decision itself gets a line under Decisions saying where it came from ("from review", "answer to the worker's question").
- Tell the worker `ticket.md` changed before it continues.
- At Report, and after each review round, write the amendments back to the tracker: patch the Decisions and Scope sections per [trackers.md](../plan-work/references/trackers.md), or edit the markdown ticket file. If the repo has its own ticket skill, follow its rules for edits. Don't change status, assignee or priority.

## Rules

- **Never answer an approval dialog or a question for the user.** Relay it exactly as it appears.
- **Draft PRs only.** Never mark a PR ready, merge, or request reviewers.
- **No tracker status changes** unless the repo's ticket skill says to do them. Writing amendments back is the only ticket edit.
- **Never close the worktree, pane or workspace.** Cleanup after merge is the user's call.
- **Never copy production data into briefs, tests, or demos.** Tests use synthetic data; demos use the shared non-production environment's existing data, read-only.
