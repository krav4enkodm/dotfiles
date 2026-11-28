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
  Loading a small, bounded set and counting in code is fine when it reads
  better; say why it stays small.
- **Bound every list:** paginate or cap, and validate the cap before the loop.
- **No N+1.** Batch per-row lookups, preload what a loop reads, don't fetch a
  row twice or re-read one you just wrote.
- **Index what you filter and join on,** and only that: an index must match the
  real query shape (optional filters, sort order). Don't wrap indexed columns
  in functions; store a normalised column instead.
- **Prove performance claims** with a query plan, a timing or a row count.
- **Group writes that must succeed together** in one transaction; prefer one
  bulk statement to a loop of single updates.
- **Store money and measures as integers** in the smallest unit.

## Schema and rollout

- **Old code runs against the new schema** while the deploy rolls out: expand,
  migrate, then contract. Drop columns and old API fields in a later release,
  after every client has moved.
- **No lock-heavy DDL on large tables:** build indexes concurrently, avoid
  table rewrites. Never edit a migration that has shipped; give it a real down.
- **Keep model validations and database constraints in step.** Required means
  `NOT NULL`, booleans get a default, uniqueness gets a unique index. Push
  defaults and invariants into the database where it can hold them.
- **API nullability matches the column.** A non-null field over a nullable
  column breaks at runtime.
- **New columns on existing rows** get a backfill or a stated decision not to.
  A backfill selects rows the way the app does, and already-stored data must
  still parse under a stricter schema; check production data, not only a test
  environment.
- **Backfills and scripts are safe to rerun:** dry-run by default, page with a
  cursor so failing rows don't stall progress, run where production credentials
  already live.
- **New settings and secrets exist in every environment** before the code that
  reads them merges.
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
