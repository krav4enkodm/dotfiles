---
name: work-plan
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
- **Plan for parallel work.** `work-work` runs every ticket whose blockers allow it at the same time. Shape the split and the links so as much as possible can run at once, without making tickets smaller than a PR worth reviewing.
- **Ask well.** Questions follow [references/interview-rules.md](references/interview-rules.md): one recommended option each, explained with a concrete scenario.

## Step 0: size the work

- **Task:** one PR, one ticket. Skip steps 3 and 4, and keep step 2 to a paragraph.
- **Feature:** 2–4 PRs.
- **Project:** 5+ PRs, often several waves wide.

A feature or project gets a container in the tracker (project / epic / milestone) holding the wave table; `work-work` runs the plan from it.

State the size in one line, then proceed. Re-size if the work grows.

**Shortcut:** if the user hands you existing tickets and asks whether they're ready, save their text as drafts (step 5) and start at step 6. If they have no waves yet, derive them from their links as in step 4.

## Steps

1. **Understand and ground.** Restate the goal in one or two sentences. Find what already exists: code that produces or consumes the data, similar features to copy, auth/access patterns, deploy and CI flow, environments. For UI work, pull the mockup per [references/design.md](references/design.md); what you find becomes the ticket's Design section and its questions. For a bug, reproduce it or find the failing path in the code first; that becomes the ticket's Reproduce section.
2. **Approach.** Give options with a recommendation and the trade-offs that matter (security, cost, blast radius, effort). For a task, one paragraph is enough.
3. **Split into pieces** (feature/project). Each piece must be safe to ship on its own. Put a change that widens access or trust in the same piece as the thing that needs it, never after. Note which pieces can be verified where.
   - **Cut along file and module boundaries**, so pieces can be built at the same time without touching the same files. Never split just to get more tickets: each piece is still a PR worth reviewing on its own.
   - **Shared contracts get their own ticket.** When two pieces share an API shape, a type, or a schema field, put that contract in a small ticket the others are blocked by. Parallel workers then build on real code instead of two copies of a description.
4. **Dependency graph and waves** (feature/project). Every ticket goes to `work-work`, so the graph is the only limit on parallel work.
   - Link each ticket to the tickets it really needs to work (blocked-by), and nothing else. Order alone is not a dependency.
   - Derive the waves: a ticket with no blockers is in wave 1; any other ticket is one wave after its latest blocker. Write it on the ticket's first line: "Wave 2 · blocked by 01, 03." Never write stack positions: `work-work` publishes a chain of single-blocker tickets as a `gh stack` on its own.
   - **Keep fan-in rare and late.** A ticket with two or more blockers waits until all but one of them have merged, so it waits on reviews. Push it to the end, e.g. a final wiring or feature-flag ticket.
   - **No overlap inside a wave.** Two tickets in the same wave never change the same file; the cross-ticket review checks it.
   - Put pieces that need ops setup or production-only verification in the last wave.
5. **Draft tickets** using the template in [references/definition-of-ready.md](references/definition-of-ready.md). Write each draft to `~/work-work/<repo>/plans/<slug>/NN-<slug>.md`, outside the repo and the tracker, and the wave table (below) to `README.md` in the same folder. Nothing is created in the tracker until the review is clean, so it never holds half-finished tickets patched round after round. Unknowns go in the ticket as open questions, never invented.
6. **Review until clean.** Loop: run the readiness review (below; from round 2, only on tickets changed since the last round, plus the cross-ticket pass) → apply everything the code answers and list those fixes in one short message → ask the user the remaining questions per [references/interview-rules.md](references/interview-rules.md) and apply the answers. Stop when a review finds no blockers or gaps. If questions are still open after **3** rounds, stop and list them per ticket. Let the user choose: defer each one with a default (the Definition of Ready allows that), or keep planning.
7. **Create in the tracker** per [references/trackers.md](references/trackers.md), now that the drafts are stable. Confirm titles, waves and container in one message, then create the tickets and their blocked-by links, put the wave table in the container, and replace the draft numbers on first lines and in the table with the tracker's ids. A task needs no container or table: its one ticket says "Wave 1." For existing tickets (the shortcut below step 0), patch the changed sections instead.
8. **Report:** the wave table with links, decisions made, anything deliberately deferred.

## Running the readiness review

Use the checks in [references/review-checklist.md](references/review-checklist.md).

**Inline vs subagents.** For 1–2 tickets, review inline: it's cheaper and just as good. For 3+ tickets, or when a check needs a wide codebase sweep, fan out to the `readiness-reviewer` agent, one ticket per agent, in parallel. Give each one what its "Input" section asks for.

**Always add a cross-ticket pass** after the per-ticket reviews, inline or as one more `readiness-reviewer` call in cross-ticket mode with all tickets. Per-ticket reviewers can't see contracts between tickets (what one ticket sends vs what another accepts), duplicated or orphaned scope, or wrong dependency links.

## The wave table

The plan at a glance, kept in the plan's `README.md` and in the container:

```markdown
| Wave | Ticket | Blocked by | Changes |
|---|---|---|---|
| 1 | 01 Add the order API contract | — | `api/orders/schema.ts` |
| 1 | 04 Copy and translations | — | `i18n/checkout/*` |
| 2 | 02 Order service | 01 | `server/orders/*` |
| 2 | 03 Checkout UI | 01 | `web/checkout/*` |
| 3 | 05 Wire up behind a flag | 02, 03 | `web/routes.ts`, `flags.ts` |
```

"Changes" lists the main files or folders from each ticket's Scope; it is what the overlap check reads. When a review round changes links or scope, update the table too.

**Merging results.** De-duplicate findings across reviewers, then handle them as in step 6, questions highest-impact first.

## Done

Every ticket meets the Definition of Ready, the last review found no blockers or gaps, and the user has the links. Suggest running the whole plan with `/work-work <container>` (the plan folder, for markdown tickets), or `/work-work <ticket id>` for a task. It starts each ticket as soon as its blockers allow. `work-work` only runs when the user types it, so don't try to invoke it, and don't start implementing unasked.
