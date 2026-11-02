---
name: plan-work
description: Turn an idea, feature, project, or rough ticket into ready-to-implement tickets, grounded in the codebase. Sizes the work (task / feature / project), proposes an approach, splits it into shippable pieces, drafts tickets, then loops a readiness review and a gap-filling interview until every ticket meets the Definition of Ready. Use when the user asks to plan, scope, break down, or ticket some work, asks "is this ticket ready?", or wants to make existing tickets ready to implement. Not for implementing the work itself.
argument-hint: "[what to build, or ticket IDs to check]"
---

# Plan work to ready-to-implement

The output is a set of tickets (one or many) that each meet the Definition of Ready in [references/definition-of-ready.md](references/definition-of-ready.md). Everything else in this skill serves that.

## Principles

- **Ground every step in the code.** Read what exists before proposing; re-read when a ticket makes a claim about the code. Most real gaps are found in the code, not in conversation.
- **Draft before asking.** Questions against a concrete draft are answerable; abstract questions up front are not. The core loop is draft → review → ask → update, until clean.
- **Ask decisions, fix facts.** If the code, docs, or installed dependencies answer it, apply the fix and say so. Only questions with a real choice reach the user.
- **Verify library behaviour in the installed source** (e.g. `node_modules`, site-packages), not from memory. Ordering and default behaviours are where plans go wrong.
- **Recommend, don't survey.** Every option list has one recommended option and a one-line reason.
- **Plain language to the user.** Explain any question with a concrete scenario. If the user says they don't understand, re-explain with an example; never repeat the same wording.

## Step 0: size the work

| Size | Signal | Steps that apply |
|---|---|---|
| **Task** | One PR, one ticket | 1, 2 (brief), 5, 6, 7, 8, 9 |
| **Feature** | 2–4 PRs | All |
| **Project** | 5+ PRs or several tracks | All, plus a project/epic container in the tracker |

State the size and the steps you'll run in one line, then proceed. Re-size if the work grows.

**Shortcut:** if the user hands you existing tickets and asks whether they're ready, start at step 6.

## Steps

1. **Understand and ground.** Restate the goal in one or two sentences. Find what already exists: code that produces or consumes the data, similar features to copy, auth/access patterns, deploy and CI flow, environments.
2. **Approach.** Give options with a recommendation and the trade-offs that matter (security, cost, blast radius, effort). For a task, one paragraph is enough.
3. **Split into pieces** (feature/project). Each piece must be safe to ship on its own. Put a change that widens access or trust in the same piece as the thing that needs it, never after. Note which pieces can be verified where.
4. **Delivery shape** (feature/project). Ask about team size if unknown. Choose a stack or parallel tracks; order by real dependencies; put pieces that need ops setup or production-only verification last. Deliver a stack with `gh stack` if the extension is installed (`gh extension list`); otherwise use plain branches whose PRs target the branch below.
5. **Draft tickets** using the template in [references/definition-of-ready.md](references/definition-of-ready.md). Create them in the tracker per [references/trackers.md](references/trackers.md). Unknowns go in the ticket as open questions, never invented.
6. **Readiness review.** See "Running the readiness review" below.
7. **Interview** to resolve the review's questions, following [references/interview-rules.md](references/interview-rules.md). Apply each answer to the affected tickets as you go.
8. **Close remaining unknowns** by checking code and installed dependencies. Anything still open after that is a question for step 7.
9. **Repeat 6–8 until a review comes back clean**, then report: tickets and links, decisions made, anything deliberately deferred.

## Running the readiness review

Use the checks in [references/review-checklist.md](references/review-checklist.md).

**Inline vs subagents.** For 1–2 tickets, review inline: it's cheaper and just as good. For 3+ tickets, or when a check needs a wide codebase sweep, fan out to the `readiness-reviewer` agent, one ticket per agent, in parallel, with `effort: "lower"` unless a ticket touches auth, data integrity, or money.

Give each reviewer, in its prompt:
- the ticket's full text (the reviewer does not read the tracker);
- the one-paragraph goal of the whole piece of work, plus the titles of sibling tickets and what each owns;
- decisions already made, so it doesn't re-ask them;
- the repo path and any areas to look at first.

**Always add a cross-ticket pass** after the per-ticket reviews, inline or as one more `readiness-reviewer` call in cross-ticket mode with all tickets. Per-ticket reviewers can't see contracts between tickets (what one ticket sends vs what another accepts), duplicated or orphaned scope, or wrong dependency links.

**Merging results.** De-duplicate findings across reviewers. Apply "resolved from code" items to the tickets directly and list them in one short message. Batch the questions for step 7, highest-impact first.

## Done

Every ticket meets the Definition of Ready, the last review found no blockers or gaps, and the user has the links. Offer to start the first piece with the `work-work` skill, bottom of the stack first; don't start implementing unasked.
