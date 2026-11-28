---
paths:
  - "**/*.{rb,py,go,java,kt,scala,cs,php,ex,exs,rs}"
  - "**/{server,backend,api,services,jobs,workers,consumers,handlers}/**/*.{ts,js,mjs}"
---

# Backend reliability

Code runs more than once, out of order, halfway, and next to other code doing
the same thing. Write it for that.

## Failures

- **Fail loudly on states that should be impossible.** Where your own code
  guarantees a value, don't guard it: no safe navigation, nil checks, fallback
  chains, non-raising saves or "report and carry on". Raise where the invariant
  breaks, so the bug shows at its source instead of as wrong data or an email
  to the wrong person. Required lookups use the raising form; a branch over
  known variants raises on an unknown one. Untrusted input is different:
  validate it and return a clear error.
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
  - The code that does the work marks it done, after it succeeds; not the code
    that enqueues it.
  - A move copies everything first and deletes last, so a rerun can resume.
  - A rollback undoes your marker but not an email already sent: don't wrap a
    rerunnable batch with irreversible side effects in one transaction.
- **Don't hold a transaction or lock across a slow external call.**
- **Fail where someone can act.** Misconfiguration surfaces when the operator
  sets it up, not when a customer opens a page; users see a safe message, never
  internal IDs or stack details.

## Retries, duplicates and races

- **Every retried or replayed unit is idempotent.** Assume the call succeeded
  but the response was lost, ran twice at once, or is replayed days later.
  Back it with a unique constraint plus create-or-find, or a compare-and-set
  claim before the external call and a marker a retry can find.
- **A repeatable action returns early when its state is already set,** and
  that no-op writes no audit entry, emits no event and calls no external
  service again.
- **"In progress" can't outlive a crash:** give claims a timestamp or expiry, or
  a recovery path.
- **Publish after commit.** An event sent before the transaction commits is
  read by a consumer that sees the old data; put what it needs in the payload.
- **Use atomic updates** (increment, append, conditional update) instead of
  read-modify-write, and don't let two writers null out each other's columns.
- **Lock everything the invariant spans, then re-read.** Reload the row after
  taking the lock, lock every row whose state you check, and don't let a lock
  that's already held silently skip valid work.
- **Per-call state stays out of shared state.** No request data in class-level,
  static or global variables, process environment or a library's global
  settings: concurrent calls overwrite each other.
- **A shared code path changes for every caller.** Before adding or removing a
  side effect or guard on reusable code, list its callers and decide for
  each; a guard added to one of several sibling paths usually belongs on all.
- **Size the load you put on a queue.** Estimate how many jobs or events a
  backfill or fan-out creates, batch per chunk rather than per row, drop no-op
  work before enqueueing, and pace it so shared consumers keep up.
- **Don't rely on an order nobody guarantees:** external API sort order, event
  delivery order, creation time as "latest" when edits or restores exist.
- **Don't build guards the platform already gives you** (once-per-key
  execution, a concurrency limit), or against a duplicate nobody would mind.
- **Call third parties asynchronously** unless the response decides the
  request's outcome or the user can fix its failure.

## Edge cases

- **Never guess a match.** "First", "newest" or name-only lookups must not pick
  one of several candidates; an ambiguous result is its own outcome. Never key
  logic on a name users can edit or on text stored in a free-text field; add a
  stable identifier. Check which scope an external ID is unique in, and check
  the type as well as the id of a polymorphic reference.
- **Handle every state you branch on,** not only the happy one, and every
  degenerate input: empty list, duplicates in one payload, blank vs missing,
  future timestamps, both or neither of two exclusive arguments.
- **Keep unknown apart from empty** where callers act differently on them:
  return null for a missing value, never `''`, `0` or placeholder text; a list
  is an empty list, not null; "clear this field" differs from "not sent".
- **A case that legitimately can't succeed** (the external state it needs is
  gone) **returns a skipped result** instead of raising on every retry.

## Observability

- **No silent outcomes.** Every skip, cap, fallback or "needs review" leaves a
  queryable status, a metric or a log at the right level, and an alert where
  someone must act. A missing setting that disables a feature must not look
  healthy. A sub-step that returns without doing its work must not let the
  caller carry on as if it had: check its result before what depends on it.
- **Log for a reader.** Add a log only if someone will act on it; don't page on
  expected states.
- **Scheduled jobs get failure and staleness monitors; queues get a
  dead-letter alarm** and a note on how to redrive.
