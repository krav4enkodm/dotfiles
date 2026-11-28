---
paths:
  - "**/*.{rb,py,go,java,kt,scala,cs,php,ex,exs,rs,sql}"
  - "**/{migrations,migrate,db,schema}/**"
  - "**/{server,backend,api,services,jobs,workers,consumers,handlers}/**/*.{ts,js,mjs}"
---

# Backend data

Follow the repo's migration and data-protection guides first; these are the
defaults where they say nothing.

## Queries

- **Let the database do the work.** Filtering, sorting, limits, time windows
  and aggregation go in the query, not in memory after an unbounded fetch.
  Don't load a growing list of ids to pass back as `IN (…)`: use a join, a
  subquery or `NOT EXISTS`. Loading a small, bounded set and counting in code
  is fine when it reads better; say why it stays small.
- **Fetch only what the decision needs:** an existence check instead of
  loading rows, ids instead of the associated records, no join you don't
  filter on, no re-fetch of a row you already hold.
- **Bound every list:** paginate or cap, and validate the cap before the loop.
- **No N+1.** Batch per-row lookups and preload what a loop reads.
- **Index what you filter and join on,** and only that: an index must match the
  real query shape (optional filters, sort order, a partial index when most
  rows are null). Don't wrap indexed columns in functions; store a normalised
  column instead. Before dropping or replacing an index, check production
  doesn't use it, and add the replacement in an earlier release.
- **Prove claims with production numbers:** a query plan, a timing, a row
  count; and before adding handling for nulls, duplicates or "latest", count
  the real cases.
- **Group writes that must succeed together** in one transaction; prefer one
  bulk statement to a loop of single updates.
- **Store money and measures as integers** in the smallest unit.

## Schema and rollout

- **Old and new code run side by side** while a deploy rolls out: expand,
  migrate, then contract.
  - Old code runs against the new schema: drop columns and old API fields in a
    later release, after every client has moved.
  - New code runs before data migrations and backfills finish: ship reference
    and config rows first, or tolerate their absence, and set the new value on
    every write path, since rows written mid-deploy miss a one-off backfill.
  - Work already queued is a consumer too: jobs, messages, cached clients and
    links in sent emails. Change job arguments in two steps (accept both, drop
    the old once the queue drains), and check queues and access logs before
    deleting a job class, handler or route.
- **No lock-heavy DDL on large tables:** build indexes concurrently, add
  constraints as not-yet-validated and validate separately, avoid table
  rewrites. Never edit a migration that has shipped; give it a real down, or
  mark data removal as irreversible. A migration doesn't use app models or
  constants that may later change or disappear; it inlines what it needs.
- **Keep model validations and database constraints in step.** Required means
  `NOT NULL`, booleans get a default, "at most one per parent" gets a composite
  unique index (which also covers lookups on its leading column). Add a
  constraint in order: every writer complies, then backfill or deduplicate,
  then constrain. Push defaults and invariants into the database where it can
  hold them.
- **API nullability matches the column.** A non-null field over a nullable
  column breaks at runtime.
- **Persisted identifiers are a contract.** Type names stored in rows, codes,
  enum strings and event names are read by old rows, other services and
  analytics: don't rename them in place; map the old value, or ship a reader
  that accepts both first.
- **A derived store's schema change is a migration.** A new field or analyzer
  in a search index, cache or read model is missing from existing documents
  until rebuilt: plan the rebuild, its duration and what queries return
  meanwhile.
- **New columns on existing rows** get a backfill or a stated decision not to.
  A backfill selects rows the way the app does, and already-stored data must
  still parse under a stricter schema; check production data, not only a test
  environment.
- **Backfills and scripts are safe to rerun:**
  - dry-run by default, run where production credentials already live, and
    estimate the run time at production size; long runs go to a background
    job;
  - survive a partial failure, and send no notification or event twice;
  - page with a cursor so failing rows don't stall progress; when each batch
    changes which rows match, re-query from the start instead of moving an
    offset;
  - look rows up by a stable key, never a hardcoded id that differs between
    environments;
  - per-row bulk work continues and reports skipped rows where someone reviews
    them; a small reference or config change fails loudly instead. Never make
    error handling depend on the environment.
- **New settings and secrets exist in every environment** before the code that
  reads them merges. Hosts and URLs come from configuration, never from the
  environment's name or a hardcoded production host.
- **Work skipped while a flag was off** is either picked up later or knowingly
  dropped.

## Personal data

- **Trace personal data through every sink:** logs, error messages, URLs,
  queue bodies and dead letters, job history, monitoring, email subjects,
  third parties. Redaction covers every nesting level and path shape.
- **Who can call it, and what else exposes it?** Hiding a field in one API
  means nothing if an export or another endpoint still returns it. Public and
  unauthenticated endpoints get rate limits, input bounds and bot protection;
  verify webhook signatures on the raw payload with a constant-time compare.
- **Plan the lifecycle:** deleting a parent must not orphan child rows holding
  personal data, and a cascade must not erase a record you are required to keep.
- **A new purpose, transfer or wider permission waits for sign-off,** behind a
  switch that is off by default, and the data inventory is updated with it.
