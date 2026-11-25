---
name: work-plan-split
description: Split phase of work-plan; run only by the work-plan skill, with the plan folder as its argument. Cuts the approved brief and contracts into ticket drafts that meet the Definition of Ready, linked into waves so as much as possible runs in parallel, and loops until plan.mjs check passes. Never asks the user.
argument-hint: "<plan dir>"
user-invocable: false
context: fork
---

# Split

Plan folder: `$ARGUMENTS`. Formats: `~/.claude/skills/work-plan/references/plan-files.md`. Ticket template and Definition of Ready: `~/.claude/skills/work-plan/references/definition-of-ready.md`. UI tickets: `~/.claude/skills/work-plan/references/design.md`.

Read `state.json`, `brief.md`, `decisions.md`, `contracts.md` (absent for a task), everything in `context/`, and any existing drafts. Write only `NN-<slug>.md`, `README.md` and, for a choice the inputs don't settle, `questions.md`.

Every ticket goes to `work-work`, which starts each one as soon as its blockers allow, in its own worktree. So the dependency graph is the only limit on parallel work, and two tickets in the same wave must never change the same file.

## Cut the pieces

A task is one ticket: skip to "Draft". Otherwise:

- **Each piece is safe to ship alone.** Merging and deploying it without the tickets after it breaks nothing and exposes nothing. A change that widens access or trust goes in the same piece as the thing that needs it, never after.
- **Each piece is a PR worth reviewing.** Never split just to get more tickets; merge pieces that are too small to review on their own.
- **Contracts first.** Each contract in `contracts.md` lands in a wave-1 ticket in its owner repo; small contracts in one repo can share a ticket. A contract used by another repo also gets a wave-1 ticket there (its types and fixtures, quoting the same section of `contracts.md`). Parallel workers then build on real code, not on a description.
- **Cut along file and module boundaries**, per repo:
  - **UI:** cut along the inventory. A section or modal that's a PR worth reviewing is its own ticket, built against its props contract and fixtures and shown in isolation the way the repo does it (a story, a test page). Fetching the screen's data is its own ticket, against the view-model contract and fixtures. Assembling the screen (route, layout, wiring sections to data) is a late ticket. Switching from fixtures to an API in another repo is its own last-wave ticket, blocked by the API ticket, so the UI waves never wait on backend review.
  - **Backend:** data model and migration first, then each endpoint from its contract, with its access checks in the same ticket.
- **Ops last.** Pieces that need ops setup or production-only verification go in the last wave.

If a real choice remains that the brief and contracts don't settle (two cuts with different trade-offs), add a question for phase `split` and stop; don't pick silently.

## Link them into waves

- Link each ticket to the tickets it really needs to work (blocked-by), and nothing else. Order alone is not a dependency.
- A ticket with no blockers is in wave 1; any other is one wave after its latest blocker.
- **Keep fan-in rare and late.** A ticket with two or more blockers waits until all but one have merged, so it waits on reviews. Push it to the end.
- **No overlap inside a wave**, per repo. If two tickets in a wave need the same file, move the shared change to an earlier ticket or block one on the other.

## Draft

Write each ticket to `NN-<slug>.md`, numbered across the whole plan, using the template:

- First line: `Wave N.` or `Wave N · blocked by 01, 03.` then one sentence on what it delivers.
- `Repo: <name>` when the plan spans several repos; `Covers:` with every brief, inventory and contract id it delivers.
- "Done when" comes from the brief's examples it covers, as named tests, plus a manual check in a named environment.
- UI tickets get a Design section per `design.md`, from the inventory entries they cover.
- Decisions from `decisions.md` and answered questions that shape the ticket go under its Decisions.
- Unknowns stay as open questions in the ticket, never invented.

Write the wave table to `README.md` (Repo column when there are several repos), "Changes" listing each ticket's main files or folders from its Scope.

## Check

Run `node ~/.claude/skills/work-plan/scripts/plan.mjs check $ARGUMENTS` and fix every error: an uncovered id gets a ticket or, if it's truly excluded, a question asking whether to mark it `[out]`; an overlap means a different cut or a link. Repeat until it passes. Warnings about fan-in are worth one more look at the cut.

## Return

Exactly one line, then the wave table:

- `PHASE split: DONE` when `check` passes;
- `PHASE split: NEEDS-ANSWERS <n>` when a question from phase `split` is `open`.
