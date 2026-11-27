---
paths:
  - "**/*.{rb,py,go,java,kt,scala,cs,php,ex,exs,rs}"
  - "**/{server,backend,api,services,jobs,workers,consumers,handlers}/**/*.{ts,js,mjs}"
---

# Backend reliability

Code runs more than once, out of order, halfway, and next to other code doing
the same thing. Write it for that.

## Failures

- **Decide what each failure means.** A transient error (timeout, 429, 5xx,
  deadlock, restart) is retried; a permanent one (bad input, missing config,
  4xx) is not retried forever and is not marked final if fixing the config
  would let it succeed. A catch-all that returns nothing should only cover
  "not found".
- **Classify errors by type or code,** never by matching the message text.
  Your client's own error class belongs in the retryable list.
- **Don't swallow errors inside a retried unit** (a job, a step, a handler):
  the runner then thinks it succeeded and never retries. Let it raise; catch
  outside if later work must still run.
- **Walk every interruption point when two systems can't commit together**
  (database plus an external API, queue or another store): nothing lost, nothing
  stuck, nothing done twice. Do the most important side effect first, and don't
  let one provider's outage block an unrelated critical step.
- **Don't hold a transaction or lock across a slow external call.**
- **Fail where someone can act.** Misconfiguration surfaces when the operator
  sets it up, not when a customer opens a page; users see a safe message, never
  internal IDs or stack details.

## Retries, duplicates and races

- **Every retried or replayed unit is idempotent.** Assume the call succeeded
  but the response was lost, ran twice at once, or is replayed days later.
  Back it with a unique constraint plus create-or-find, or a compare-and-set
  claim before the external call and a marker a retry can find.
- **A repeatable action returns early when its state is already set.**
- **"In progress" can't outlive a crash:** give claims a timestamp or expiry, or
  a recovery path.
- **Publish after commit.** An event sent before the transaction commits is
  read by a consumer that sees the old data; put what it needs in the payload.
- **Use atomic updates** (increment, append, conditional update) instead of
  read-modify-write, and don't let two writers null out each other's columns.
- **Don't rely on an order nobody guarantees:** external API sort order, event
  delivery order, creation time as "latest" when edits or restores exist.
- **Don't build guards the platform already gives you** (once-per-key
  execution, a concurrency limit), or against a duplicate nobody would mind.
- **Call third parties asynchronously** unless the response decides the
  request's outcome or the user can fix its failure.

## Edge cases

- **Never guess a match.** "First", "newest" or name-only lookups must not pick
  one of several candidates; an ambiguous result is its own outcome. Check
  which scope an external ID is unique in.
- **Handle every state you branch on,** not only the happy one, and every
  degenerate input: empty list, duplicates in one payload, blank vs missing,
  future timestamps, both or neither of two exclusive arguments.
- **Keep unknown apart from empty** where callers act differently on them.
- **A case that can never succeed returns a skipped result** instead of
  raising on every retry.

## Observability

- **No silent outcomes.** Every skip, cap, fallback or "needs review" leaves a
  queryable status, a metric or a log at the right level, and an alert where
  someone must act. A missing setting that disables a feature must not look
  healthy.
- **Log for a reader.** Add a log only if someone will act on it; don't page on
  expected states.
- **Scheduled jobs get failure and staleness monitors; queues get a
  dead-letter alarm** and a note on how to redrive.
