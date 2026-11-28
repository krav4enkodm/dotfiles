---
paths:
  - "**/*.{rb,py,go,java,kt,scala,cs,php,ex,exs,rs}"
  - "**/{server,backend,jobs,workers,consumers}/**/*.{ts,js,mjs}"
  - "**/apps/{api,server,backend,worker}*/**/*.{ts,js,mjs}"
  - "**/{app,pages}/api/**/*.{ts,js}"
  - "**/*.{controller,repository,entity,job,worker,consumer}.{ts,js}"
---

# Backend design

Code is read far more often than it is changed. Hard-to-follow code is a defect
even when it works.

For code that serves requests, runs jobs or owns stored data. In a CLI, a
library or a one-off script, apply only what fits it.

## Where logic lives

- **Logic lives with the concept it is about.** A rule about an entity is a
  method on that entity or in the module that owns that domain ("tell, don't
  ask"), not in an API resolver, serializer, controller, initializer or a
  caller that inspects its state. A check repeated in several places is a
  missing method: reuse the domain's predicate instead of re-deriving it from
  raw columns or a hand-picked list of statuses, because copies drift when
  the definition changes.
- **Each variant's behaviour lives in one place:** its own class or handler,
  or one exhaustive match over a closed type, whichever the language makes
  idiomatic. Shared code doesn't grow `if kind == X` special cases, and a
  variant is defined by what it is, not as "not A and not B", which silently
  matches the next variant added.
- **Configuration is data.** Per-variant switches are an attribute on the
  configuration record, not a list of hardcoded types, IDs or people in code.
  Things operations change belong where they can change them without a deploy.
- **Single-use helpers stay with their owner** (private method, nested module),
  not in a shared folder or on a widely used model. Every field, association
  or method added to a central entity widens its interface, hides queries and
  points dependencies the wrong way: the feature queries the central entity,
  not the reverse.
- **Cross-domain side effects go through domain events** when other entry
  points would otherwise bypass them.
- **Respect module boundaries.** Declare real dependencies, never create a
  cycle, and don't contort the code to dodge a boundary check.
- **Don't extend a mechanism that is being retired,** and delete what can no
  longer run: fully rolled-out flags, options never enabled, fallbacks for a
  data shape a finished migration removed, and what they leave unused.

## Simplicity

- **Reuse before you add.** Search for an existing field, endpoint, job,
  helper, query or retry utility that already does this, and extend it.
  Parallel versions drift, and consumers can't tell which one to trust.
- **Prefer the shape a reader can predict:** guard clauses over nested
  conditions, one linear method over a chain of tiny ones, explicit arguments
  over base-class constants or metaprogramming, a plain `switch` or `match`
  over calling methods by a name built from data.
- **Code that computes doesn't change state.** A method that calculates or
  reads doesn't also update a flag or mutate its inputs; state changes are
  explicit, named and in one place.
- **Return one shape.** One type per function; a collection returns empty, not
  null, unless null means "unknown" to callers.
- **A little duplication beats the wrong abstraction.** Share contracts,
  encodings and rules that must agree; don't force loosely similar logic into
  a shared mixin or inheritance tree.
- **Build for today; choose a cheap shape for tomorrow.** No parameters,
  columns, statuses, flags, caches or wrapper classes until the change that
  needs them, but pick an extensible shape when it costs nothing (an enum or
  list instead of a boolean, return the richer object).
- **Justify added machinery with numbers:** expected load, latency, hit rate.
- **Pass the narrowest thing that works:** IDs and values to jobs, the
  aggregate instead of pieces derivable from it, no flag parameter that only
  restates persisted state.
- **Model coupled values together:** an amount with its currency, a value with
  its unit.
- **Implementation details stay private.** Adding a cache or an optimisation
  doesn't change the public interface.
- **Derive cache keys from what the value depends on** (the record's version
  or update time) instead of invalidating by hand, and align expiry with the
  refresh cadence.
- **Extend a library before replacing it.**

## API contracts

- **Design for the consumer.** Expose what a client needs and nothing more: no
  IDs or fields without a reader, no UI strings or screen-specific fields.
  Compute per-entity rules on the server so clients don't re-implement them.
- **Make invalid combinations unrepresentable.** One variant type per case (a
  union, or an enum with per-variant fields) instead of a kind flag and
  loosely related nullable fields; values that must come together travel in
  one input; don't accept two inputs that can contradict each other.
- **Group related fields** under a nested object instead of prefixed flat
  fields.
- **A write returns what the client needs to show its result,** usually the
  updated resource, so the client doesn't have to fetch it again.
- **Arguments are strict and composable:** required when required, one enum or
  list instead of a boolean per case.
- **Write the published schema explicitly.** Don't generate fields or enum
  values from database rows or runtime constants; list them, with a test that
  keeps them in step with their source.
- **Never break a published contract.** Removing a field or enum value waits
  until every client has stopped using it; old clients live for months. A new
  variant in a union or polymorphic field, or a new format for a stored key,
  breaks them too. A deprecation note names any behaviour difference in the
  replacement.

## Explaining

- **Comment the why, never the what:** a non-obvious branch gets its business
  reason, an odd construct gets its constraint. A complex process gets a short
  class-level overview.
- **Errors tell the reader how to fix them,** naming the exact thing to change.
- **Names say what a thing is or what callers get,** not how it is built: no
  abbreviations, no implementation or transport names in API and method names,
  and the codebase's established domain term rather than a synonym. Keep names
  searchable: no class names built from strings, no domain meaning hidden in a
  generic override such as a string conversion.
