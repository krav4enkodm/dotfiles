---
name: backend-review
description: Review backend changes (a branch diff, a PR number or URL, or given files) the way a senior backend reviewer does — runtime risk (failure paths, retries, idempotency, races, data safety, rollout) and design (where logic lives, simplicity, API contracts, tests) — and report findings by severity, each with its cost and a fix. Stack and project agnostic. Use when asked to "review this backend change", "backend review", "/backend-review", or for a pre-merge review of server-side code, migrations, jobs, consumers or integrations.
---

# Backend review

Review a change the way an experienced backend reviewer does, through two
lenses:

- **Runtime:** what the diff does across systems and over time — when a call
  fails halfway, runs twice, runs concurrently, runs before the deploy
  finishes, or meets real production data.
- **Design:** whether the next developer can read, predict and change it —
  where logic lives, how simple it is, what contract it gives its consumers,
  and whether its tests prove anything.

The checklist is the backend rule files; they are the single source of the
principles, written for authors. This skill adds how to review against them.

| Area | Rule file |
|---|---|
| Failures, retries, idempotency, races, edge cases, observability | `~/.claude/rules/backend-reliability.md` |
| Queries, schema and rollout, personal data | `~/.claude/rules/backend-data.md` |
| Where logic lives, simplicity, API contracts, explaining | `~/.claude/rules/backend-design.md` |
| Tests | `~/.claude/rules/backend-tests.md` |

## Input

The caller names one of:
- nothing → the current branch against its base (`git merge-base HEAD <default branch>`);
- a PR number or URL → `gh pr view <n> --json title,body,baseRefName,headRefName,files` and `gh pr diff <n>`;
- paths or a commit range.

Stay read-only: don't edit files, commit, push, or post anything on GitHub. The
user decides what to post.

## Procedure

1. **Read the four rule files** above in full. Then read the repo's own
   CLAUDE.md / AGENTS.md / contributing docs and rule files: where they differ
   from the backend rules, the repo wins. Note its stack, migration rules and
   deploy order (do migrations run before the new code is live?).
2. **Get the intent.** Read the PR description, the linked ticket if one is
   reachable, and the commit messages. List the acceptance criteria and every
   claim the description makes ("no public endpoint", "clamps the value",
   "backfill is idempotent"). Each claim is something to verify.
3. **Read the diff in full, then its surroundings:** callers, consumers of what
   it emits, sibling paths doing the same thing (another job, a dry-run mode,
   another endpoint exposing the same data), the schema and existing tests.
   Many of the best findings sit just outside the diff.
4. **Runtime pass.** For every changed unit, replay it under each condition:
   the external call times out; succeeds but the response is lost; runs twice
   at once; is replayed later; runs while old code is still deployed; meets
   empty, duplicate, ambiguous or legacy data; receives a caller who shouldn't
   be there. Follow personal data to every place it lands. Check each against
   the reliability and data rules.
5. **Design pass.** For each new piece of logic ask: is this the unit that owns
   the concept? Could a reader predict what it does from its shape? Does it add
   machinery the change doesn't need yet, or skip a cheap extensible shape? Is
   the API what its consumer needs, no more? Do the tests cover the risky paths
   at the right layer and fail when it breaks? Check against the design and
   tests rules.
6. **Check the change against itself:** code vs ticket and description word for
   word (trigger values, what a timer counts from, a constant that silently
   changed), changes outside the ticket's scope, a fix applied to one sibling
   but not the others, two copies of a rule that disagree, leftovers the change
   orphaned (dead code, config, mocks, debug output).
7. **Verify where it's cheap** instead of reasoning alone: run a test, a query
   plan, a script, `git log -S` for prior art. Search the repo for an existing
   helper or an earlier fix of the same problem — "reuse the pattern from X"
   beats a fresh design.
8. **Report** in the format below.

## Judging findings

- **Every finding states its cost.** For runtime findings that is a concrete
  scenario: trigger → what breaks → who is affected. For design findings it is
  what the next reader or change pays: what can't be predicted, what will
  drift, what the next variant must duplicate. A finding with neither is
  dropped.
- **Calibrate severity honestly.**
  - *Must fix:* data loss or corruption, duplicates with real effect, security
    or personal-data exposure, a broken deploy or contract, behaviour that
    contradicts the ticket.
  - *Should fix:* likely bugs on rare paths, missing tests for risky paths,
    performance that will bite at known volume, logic in the wrong place or a
    shape that will clearly cost the next change.
  - *Nit:* naming, small readability, style the linter doesn't catch.
  Say when risk is low ("internal only", "tiny table", "probably rare").
- **Ask about intent before calling something a bug** when it might be
  deliberate, and state the consequence if it isn't.
- **Settle tensions between rules case by case,** and say which way you leaned:
  - build for today vs design for the next step: a cheap shape now is fine;
    runtime machinery waits until needed;
  - one source of truth vs small duplication: share contracts and encodings,
    not loosely similar logic;
  - observability vs noise: a signal where someone acts, not logs nobody reads;
  - defensive guards vs simplicity: guard what can really happen, back it with
    evidence, drop what the platform already guarantees.
- **Always offer a fix:** name the existing helper or prior change to copy, or
  give 1–3 options ranked by how little they change, with the trade-off and a
  way to verify. A short code snippet helps when the rewrite is not obvious.
- **Prefer the simpler fix;** leave genuine design trade-offs to the author.
- **Defer what isn't blocking** to a named follow-up.
- Note what the change does well when it is a real win — one line.

## Output

```
## Verdict
Approve | Approve with comments | Request changes — one sentence why.
(Conditional approvals are fine: "approve once a staging run covers X".)

## Must fix before merge
1. `path/to/file.ext:LINE` — <title>
   Cost: <scenario, or what the next change pays>
   Fix: <concrete change; options ranked if several; how to verify>

## Should fix
…same shape…

## Questions (product / intent)
- `path:LINE` — <question>, and what happens under each answer.

## Nits (not blocking)
- `path:LINE` — <one line>

## Follow-ups (out of scope)
- <item worth its own ticket>
```

Omit empty sections and lead with the most severe finding. If nothing survives
the cost bar, say so and approve — don't manufacture comments.
