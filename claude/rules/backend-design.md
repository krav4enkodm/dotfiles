---
paths:
  - "**/*.{rb,py,go,java,kt,scala,cs,php,ex,exs,rs}"
  - "**/{server,backend,api,services,jobs,workers,consumers,handlers}/**/*.{ts,js,mjs}"
---

# Backend design

Code is read far more often than it is changed. Hard-to-follow code is a defect
even when it works.

## Where logic lives

- **Logic lives with the concept it is about.** A rule about an entity is a
  method on that entity or in the module that owns that domain ("tell, don't
  ask"), not in an API resolver, serializer, controller, initializer or a
  caller that inspects its state.
- **Variants own their behaviour.** When behaviour differs per type, the
  variant's own class or handler holds it; generic orchestrators and base
  classes only dispatch. No `if kind == X` special cases in shared code.
- **Configuration is data.** Per-variant switches are an attribute on the
  configuration record, not a list of hardcoded types, IDs or people in code.
  Things operations change belong where they can change them without a deploy.
- **Single-use helpers stay with their owner** (private method, nested module),
  not in a shared folder or on a widely used model.
- **Cross-domain side effects go through domain events** when other entry
  points would otherwise bypass them.
- **Respect module boundaries.** Declare real dependencies, never create a
  cycle, and don't contort the code to dodge a boundary check.
- **Don't extend a mechanism that is being retired.**

## Simplicity

- **Prefer the shape a reader can predict:** guard clauses over nested
  conditions, one linear method over a chain of tiny ones, explicit arguments
  over base-class constants or metaprogramming, plain `case` over dynamic
  dispatch on data.
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
- **Caches store keys, not blobs,** and derive keys from the record's version
  instead of invalidating by hand; align expiry with the refresh cadence.
- **Extend a library before replacing it.**

## API contracts

- **Design for the consumer.** Expose what a client needs and nothing more: no
  IDs or fields without a reader, no UI strings or screen-specific fields.
  Compute per-entity rules on the server so clients don't re-implement them.
- **Group related fields** under a nested object instead of prefixed flat
  fields; namespace new root fields under their domain.
- **Mutations return the object the client re-renders,** usually the parent.
- **Arguments are strict and composable:** required when required, one enum or
  list instead of a boolean per case.
- **Never break a published contract.** Removing a field or enum value waits
  until every client has stopped using it.

## Explaining

- **Comment the why, never the what:** a non-obvious branch gets its business
  reason, an odd construct gets its constraint. A complex process gets a short
  class-level overview.
- **Errors tell the reader how to fix them,** naming the exact thing to change.
- **Names say what a thing is or what callers get,** not how it is built; no
  abbreviations.
