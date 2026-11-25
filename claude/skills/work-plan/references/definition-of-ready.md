# Definition of Ready and ticket template

## Definition of Ready

A ticket is ready when all of these hold:

- [ ] **One clear outcome.** The title names it; the first line says its wave and blockers (e.g. "Wave 2 · blocked by PROJ-12").
- [ ] **Scope is concrete.** Names the files, modules, fields, endpoints, or config it changes. A new data model lists every field with type and required/optional.
- [ ] **Scope says what, not how.** Each listed change names the requirement it serves; a change no requirement needs is cut. Code shape (types, wrappers, abstractions, timeouts, caching) is prescribed only where the codebase forces it; otherwise the worker picks the simplest code that meets Done when.
- [ ] **Out of scope is explicit**, naming which sibling ticket owns each excluded part.
- [ ] **Safe to ship alone.** Merging and deploying it without the tickets above it breaks nothing and exposes nothing.
- [ ] **No open questions**, or each remaining one is explicitly deferred with a default.
- [ ] **Done when** is testable: named tests, plus a manual check in a named environment.
- [ ] **Verification environment is stated**, e.g. staging by hand, unit tests only, or production after a manual trigger.
- [ ] **Setup outside the code is a checklist**: accounts, secrets, variables, feature flags, infra, data backfills. Each item says who or where.
- [ ] **Dependencies are real.** "Blocked by" links reflect what the ticket needs to work, not the order of the plan. The wave follows from them.
- [ ] **Traceable** (tickets from a plan with a brief). `Covers:` lists the brief's rules and examples, the inventory elements and the contracts the ticket delivers, and "Done when" proves the examples it covers. A plan over several repos also names the ticket's `Repo:`.
- [ ] **Parallel-safe.** No file in its Scope is changed by another ticket in the same wave, and a contract it shares with a parallel ticket comes from a ticket in an earlier wave.
- [ ] **Claims about the code are verified**, including library behaviour, against the installed version.
- [ ] **A bug reproduces.** Steps to reproduce, expected vs actual, and where it was seen (environment, version). The first "Done when" item is a regression test that fails before the fix.
- [ ] **UI work has a Design section** per [design.md](design.md): every element the ticket adds or changes points to its design node, and everything the design can't show is written down.

## Ticket template

```markdown
<Wave and blockers, e.g. "Wave 2 · blocked by PROJ-12." or "Wave 1."> <One sentence on what this delivers.>

Repo: <name, for a plan over several repos>
Covers: <brief, inventory and contract ids, e.g. R1, E2, U3, C1>

## Reproduce

<Bugs only.>
1. <Step>

Expected: <what should happen>. Actual: <what happens>. Seen in: <environment, version>.

## Scope

- <Concrete change, with paths>
- <Data model as a table if there is one: field | type | notes>

## Design

<UI tickets only, per design.md: element map, what the design can't show, allowed deviations. Node IDs and decisions only; no copied values.>

## Out of scope

<What's excluded and which ticket owns it.>

## Decisions

<Decisions made during planning, or later during implementation (marked with where they came from): the decision and a short reason.>

## Done when

- Tests: <what they prove>
- Design (UI tickets): every element in the Design section matches its node in the running app.
- <Environment>: <manual check>

## Setup (outside the diff)

- [ ] <Account / secret / variable / infra step, and where>
```

Leave out "Reproduce", "Design", "Decisions" and "Setup" when they're empty, and the `Repo:` and `Covers:` lines when there's nothing to put in them (a single-repo plan, tickets checked without a brief). Security-relevant tickets say so on the first line and ask for the PR description to call it out.
