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
- **Ask well.** Questions follow [references/interview-rules.md](references/interview-rules.md): one recommended option each, explained with a concrete scenario.

## Step 0: size the work

- **Task:** one PR, one ticket. Skip steps 3 and 4, and keep step 2 to a paragraph.
- **Feature:** 2–4 PRs.
- **Project:** 5+ PRs or several tracks; also create a project/epic container in the tracker.

State the size in one line, then proceed. Re-size if the work grows.

**Shortcut:** if the user hands you existing tickets and asks whether they're ready, save their text as drafts (step 5) and start at step 6.

## Steps

1. **Understand and ground.** Restate the goal in one or two sentences. Find what already exists: code that produces or consumes the data, similar features to copy, auth/access patterns, deploy and CI flow, environments. For UI work, open the design too: pull each mockup node's structure, variables and screenshot, map every element to its node ID and to the design-system component that will render it, and note frames that draw a non-resting state (hover, active, open) and existing elements the mockup leaves out. These become the ticket's Design section and its questions. For a bug, reproduce it or find the failing path in the code first; that becomes the ticket's Reproduce section.
2. **Approach.** Give options with a recommendation and the trade-offs that matter (security, cost, blast radius, effort). For a task, one paragraph is enough.
3. **Split into pieces** (feature/project). Each piece must be safe to ship on its own. Put a change that widens access or trust in the same piece as the thing that needs it, never after. Note which pieces can be verified where.
4. **Delivery shape** (feature/project). Ask about team size if unknown. Choose a stack or parallel tracks; order by real dependencies; put pieces that need ops setup or production-only verification last. For a stack, write the position into each ticket's first line ("Stack 2/5"); `work-work` and `open-pr` take care of branches and `gh stack`.
5. **Draft tickets** using the template in [references/definition-of-ready.md](references/definition-of-ready.md). Write each draft to `~/work-work/<repo>/plans/<slug>/NN-<slug>.md`, outside the repo and the tracker. Nothing is created in the tracker until the review is clean. Unknowns go in the ticket as open questions, never invented.
6. **Review until clean.** Loop: run the readiness review (below) → apply everything the code answers and list those fixes in one short message → ask the user the remaining questions per [references/interview-rules.md](references/interview-rules.md) and apply the answers. Stop when a review finds no blockers or gaps. If questions are still open after **3** rounds, stop and list them per ticket. Let the user choose: defer each one with a default (the Definition of Ready allows that), or keep planning.
7. **Create in the tracker** per [references/trackers.md](references/trackers.md), now that the drafts are stable. Confirm titles, order and container in one message, then create the tickets and their blocked-by links. For existing tickets (the shortcut below step 0), patch the changed sections instead.
8. **Report:** tickets and links, decisions made, anything deliberately deferred.

## Running the readiness review

Use the checks in [references/review-checklist.md](references/review-checklist.md).

**Inline vs subagents.** For 1–2 tickets, review inline: it's cheaper and just as good. For 3+ tickets, or when a check needs a wide codebase sweep, fan out to the `readiness-reviewer` agent, one ticket per agent, in parallel. Give each one what its "Input" section asks for.

**Always add a cross-ticket pass** after the per-ticket reviews, inline or as one more `readiness-reviewer` call in cross-ticket mode with all tickets. Per-ticket reviewers can't see contracts between tickets (what one ticket sends vs what another accepts), duplicated or orphaned scope, or wrong dependency links.

**Merging results.** De-duplicate findings across reviewers. Apply "resolved from code" items to the tickets directly and list them in one short message. Batch the questions, highest-impact first.

## Done

Every ticket meets the Definition of Ready, the last review found no blockers or gaps, and the user has the links. Suggest starting the first piece with `/work-work <ticket id>`, bottom of the stack first. `work-work` only runs when the user types it, so don't try to invoke it, and don't start implementing unasked.
