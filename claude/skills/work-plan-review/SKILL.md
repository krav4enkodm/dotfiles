---
name: work-plan-review
description: Review phase of work-plan; run only by the work-plan skill, with the plan folder as its argument. Runs one readiness-review round over the ticket drafts — per ticket and across tickets — applies every fix the code settles, and records the remaining questions. Never asks the user.
argument-hint: "<plan dir>"
user-invocable: false
context: fork
---

# Review

Plan folder: `$ARGUMENTS`. Checks: `~/.claude/skills/work-plan/references/review-checklist.md` and `~/.claude/skills/work-plan/references/definition-of-ready.md`. Formats: `~/.claude/skills/work-plan/references/plan-files.md`.

One run is one review round. The coordinator runs you again after the user answers, at most three rounds.

## If answers are waiting

Apply `answered` questions from phase `review` first: put each answer in every ticket it affects, under Decisions or in Scope, then set it to `applied`. Answers go into the tickets, not `decisions.md`, so the earlier phases don't go stale.

## Pick what to review

Find the last round in `review/round-<n>/`. Round 1 reviews every ticket. From round 2, review only tickets that differ from their copy in the last round, plus the cross-ticket pass. Copy the tickets you're about to review into `review/round-<n+1>/` before you start.

## Review

**Inline or agents.** For 1–2 tickets, review inline against the checklist. For 3 or more, or when a check needs a wide sweep of the code, start one `readiness-reviewer` agent per ticket, all at once. Give each one the full ticket text; the goal and flows from `brief.md`; the sibling tickets and what each owns; the decisions already made (`decisions.md` and the tickets' Decisions), so it doesn't re-ask them; the path of the ticket's repo from `state.json`; and the contracts the ticket covers.

**Always add a cross-ticket pass**, inline or as one more `readiness-reviewer` in cross mode with all tickets and the repo paths. Per-ticket reviewers can't see contracts between tickets, duplicated or orphaned scope, or wrong links. For a plan over several repos, compare every ticket that covers the same contract: they must quote it the same way.

## Handle the findings

De-duplicate across reviewers, then:

- **Resolved from code:** apply the fix to the ticket now and keep a one-line note of it with its evidence.
- **Question:** add it to `questions.md`: `open`, its severity (`blocker` or `gap`), phase `review`, `Affects:` the ticket numbers, the reviewer's options with the recommended one first.
- **Nit:** fix it if it's wording, otherwise drop it.

If a fix changed links or Scope, update the first lines and the wave table. Then run `node ~/.claude/skills/work-plan/scripts/plan.mjs check $ARGUMENTS` and fix until it passes.

## Return

Exactly one line, then the fixes applied (one line each, with evidence) and the ids of new questions:

- `PHASE review: DONE` when this round found no blockers or gaps and no question from phase `review` is `open`;
- `PHASE review: NEEDS-ANSWERS <n>` when questions from phase `review` are `open`;
- `PHASE review: AGAIN` when every finding was resolved from code but some were blockers or gaps: the fixes need a round of their own.
