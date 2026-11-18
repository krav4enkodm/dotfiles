---
name: work-retro
description: Look back at every ticket work-work shipped whose PR merged since the last retro. For each, reads the user's conversation with the coordinator and the worker, and the PR's review comments, traces every point where the user had to step in back to its cause (planning, the ticket, or the implementation by the worker, validator or coordinator), groups the causes across tickets, and turns the picked fixes into one draft PR against this repo. Runs only as /work-retro, inside the dotfiles repo.
argument-hint: "[since date]"
disable-model-invocation: true
---

# Retro of merged tickets

A ticket that went through `work-work` with no input from the user is the target. Every time the user had to step in, the setup was missing something: the ticket didn't say it, or the worker, validator or coordinator didn't do what it said. This skill finds each of those moments across the tickets merged since the last retro, says which side it came from, and turns the fixes into a PR here. It reads; it changes nothing until the user picks the fixes.

## 1. Find the tickets

`bash .claude/skills/work-retro/scripts/merged-tickets.sh [since]` prints one line per merged ticket: merge time, project, ticket, PR, workspace, the worker's transcripts folder, and the coordinator sessions (the ones that ran `/work-work` and name the ticket). Without an argument it starts from `~/work-work/retros/last-run`, or 14 days back on the first run. If it prints nothing, say so and stop. With more than 10 tickets, show the list and ask whether to cover all of them or a shorter window.

## 2. Collect, per ticket

Run these and keep the output; don't read the raw transcripts. Collect for each ticket before you judge any of them.

- **The coordinator session.** The user talks to the coordinator there: answers its questions, directs the run, and often plans the tickets in it first. Run `bash .claude/skills/work-retro/scripts/interventions.sh --since <since> <session.jsonl>...` once per session, not once per ticket, since one session usually covers several tickets. Sessions often run for days, so `--since` (the start from step 1, or the run's first `/work-plan` if a ticket was planned before it) keeps out what happened before; anything about a ticket outside this retro is None. Give each `you` entry to the tickets it's about: the ticket it names, or the one being discussed then. Entries that apply to the whole run count once for the run. Before `/work-work` starts, the `you` entries are planning. Answers to the planner's questions are just planning. Corrections are interventions: pushing back on the split, the waves or a ticket's content, or asking "why not X?"
- **The worker conversation.** `bash .claude/skills/work-retro/scripts/interventions.sh <transcripts folder>`. It prints the worker's sessions as a timeline of tagged entries. `you`, `rejected` and `interrupted` entries are the user stepping in. `shell` entries are commands the user ran with `!`, context only. `coordinator` entries are context only: the user's answers that reached the worker that way are recorded in `ticket.md`. `blocked` entries are friction from hooks, permission rules or the auto-mode classifier. `worker asked` entries are the worker's `BLOCKED` questions: each one is an intervention even if its answer never reached Decisions. A question about the environment (no browser, no login, no app slot) belongs to Coordinator or Setup, not to the ticket. If the transcripts folder is `-`, say the conversation is gone and work from the rest.
- **The ticket as worked.** `<workspace>/ticket.md`, Decisions and Scope. Count a decision only if it was made during the work: it names a source or a date ("— user, 2026-11-04", "from review", "answer to the worker's question"). Untagged decisions date from planning.
- **Validation.** Any validator FAIL rounds recorded in the workspace (`validation*.md`, `fix-round-*.md`) or in `coordinator` entries: how many rounds, and which gaps.
- **The PR.** People's comments only; bots (the tracker's link-back, CI reports) bury the review. With `R=repos/<owner>/<repo>` and `N=<number>`:
  - `gh api $R/issues/$N/comments --jq '.[] | select(.user.type == "User") | {user: .user.login, body}'`
  - `gh api $R/pulls/$N/reviews --jq '.[] | select(.user.type == "User" and .body != "") | {user: .user.login, state, body}'`
  - `gh api $R/pulls/$N/comments --jq '.[] | select(.user.type == "User") | {user: .user.login, path, line, body}'`

  Leave out the PR author's own replies unless they settle what a reviewer asked.

## 3. Trace each intervention to its cause

Make one list per ticket, oldest first. When the same point shows up twice (a review comment and the decision it led to), keep it once. For each, answer: **what did the user have to say that the setup should have known?**

Then decide which side it came from by checking the ticket text as planned (not the amended Decisions) for the point the user made:

- **Not in the ticket** → *Ticket: missing*.
- **In the ticket, but read another way, asked about, or missed** because it was vague, abstract, buried in prose, or contradicted elsewhere → *Ticket: unclear*. Quote the ticket line next to the user's words.
- **In the ticket and clear, and the worker followed it**, but the user rejected it ("is this necessary?", "why this abstraction?", "make it cleaner") → *Ticket: wrong approach*. The plan prescribed the code, so the worker isn't at fault. Quote the ticket line.
- **In the ticket and clear**, and still not done → implementation: *Worker*, *Validator* or *Coordinator*, by who should have caught it.

A correction made while the plan was drafted goes to *Planning*, not to a ticket bucket.

| Bucket | Sign | Where the fix goes |
|---|---|---|
| Planning | You corrected the plan while it was made: the split, the waves, the size, an approach | the `work-plan` drafting steps in [SKILL.md](../../../claude/skills/work-plan/SKILL.md) |
| Ticket: missing | A missing state, behaviour, edge case or design detail | `work-plan`: usually a line in [definition-of-ready.md](../../../claude/skills/work-plan/references/definition-of-ready.md) or [review-checklist.md](../../../claude/skills/work-plan/references/review-checklist.md) that would have made planning ask |
| Ticket: unclear | The ticket said it, but not so the worker got it | `work-plan`: how tickets are written (the template in [definition-of-ready.md](../../../claude/skills/work-plan/references/definition-of-ready.md), the drafting steps in [SKILL.md](../../../claude/skills/work-plan/SKILL.md)); the fix usually cuts or sharpens text rather than adding it |
| Ticket: wrong approach | The ticket prescribed code (a shape, an abstraction, a file to change, classes to copy) that the user or a reviewer then cut | `work-plan`: how much of the solution a ticket fixes ([definition-of-ready.md](../../../claude/skills/work-plan/references/definition-of-ready.md)) and what the review challenges ([review-checklist.md](../../../claude/skills/work-plan/references/review-checklist.md)) |
| Worker | The worker did something the brief or the instructions already rule out, or missed a step of the brief | [worker-brief.md](../../../claude/skills/work-work/references/worker-brief.md); a hook or deny rule if prose has already failed (see "Which Claude Code feature holds what" in [decisions.md](../../../docs/decisions.md)) |
| Validator | The validator passed something the user then caught | the [ticket-validator](../../../claude/agents/ticket-validator.md) agent, or [design.md](../../../claude/skills/work-plan/references/design.md) for design checks |
| Coordinator | How the run was driven: start order, rebases, the app slot, messages to the worker | the [work-work](../../../claude/skills/work-work/SKILL.md) skill |
| Setup | A `blocked` or `rejected` entry that keeps happening, a permission prompt | [settings.json](../../../claude/settings.json) permissions or a hook |
| Project | A convention or fact about that codebase: a helper to reuse, a pattern, a command | that repo's own CLAUDE.md / AGENTS.md / rules; listed, not applied from here |
| None | Taste, a one-off, a question asked out of interest, a request beyond the ticket | nothing |

Read the user's messages carefully: a question ("why did you use X here?") is often a correction in disguise, and "looks good" closes a loop. Validator FAIL rounds the worker fixed alone are not interventions, but two or more rounds on the same kind of gap point at the brief or the ticket.

## 4. Report

Start with one line per ticket: `<ticket> · <n> interventions · planning + ticket <n> / implementation <n> / other <n>`, or `went through clean`. Then the totals across tickets, ticket versus implementation.

Then **group** the interventions that point at the same gap, even when worded differently or found in different projects. Each group, most tickets first:

```
1. <the gap, one sentence>   <bucket> · <n> tickets
   «<the user's words or the review comment>»  (<ticket>, pane | ticket.md | PR)
   «<ticket line>»  (Ticket: unclear only)
   Fix: <file under claude/> → <the change, specific enough to apply>
```

Before proposing a fix, read the target file as it is now; drop or rework fixes it already covers. If a group matches an entry in `~/work-work/retros/applied.md`, mark it **recurred after <PR>**, put it on top, and propose a stronger fix (a checklist item instead of a sentence, a hook instead of prose) rather than the same text again. Propose only fixes the evidence supports, and prefer changing or removing a line over adding one.

After the groups: the **Project** fixes, by project, each with the file and the change for the user to apply in that repo; then the None items in one line.

## 5. Apply

Ask which groups to apply.

1. Apply the picked ones on a branch off `main`. Write every change in generic terms: quotes, ticket keys, project names, internal packages and URLs stay out of the files, the commit and the PR (see "Keep it publishable" in CLAUDE.md). Keep README.md and its "Depends on" columns in step, and every `work-plan/references/` reference if a file moves.
2. Run `./check.sh`, commit with the `commit` skill (the body says which problem kept coming up and how often), and open a draft PR with `open-pr`.
3. Append the applied groups to `~/work-work/retros/applied.md`, each with its tickets, quotes, the fix and `Applied: <PR url>`. This file stays local: it quotes the user and names the projects' tickets.

Whether or not anything was applied, write the latest merge time from step 1 to `~/work-work/retros/last-run`, so the next retro starts after it. Groups not picked are not carried over; if they come up again they'll show in the next retro.

Don't run `./install.sh`: install from `main` after the PR merges.
