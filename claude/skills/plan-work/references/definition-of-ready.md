# Definition of Ready and ticket template

## Definition of Ready

A ticket is ready when all of these hold:

- [ ] **One clear outcome.** The title names it; the first line says where it sits (e.g. "Stack 3/6").
- [ ] **Scope is concrete.** Names the files, modules, fields, endpoints, or config it changes. A new data model lists every field with type and required/optional.
- [ ] **Out of scope is explicit**, naming which sibling ticket owns each excluded part.
- [ ] **Safe to ship alone.** Merging and deploying it without the tickets above it breaks nothing and exposes nothing.
- [ ] **No open questions**, or each remaining one is explicitly deferred with a default.
- [ ] **Done when** is testable: named tests, plus a manual check in a named environment.
- [ ] **Verification environment is stated**, e.g. staging by hand, unit tests only, or production after a manual trigger.
- [ ] **Setup outside the code is a checklist**: accounts, secrets, variables, feature flags, infra, data backfills. Each item says who or where.
- [ ] **Dependencies are real.** "Blocked by" links reflect what the ticket needs to work, not just stack order.
- [ ] **Claims about the code are verified**, including library behaviour, against the installed version.

## Ticket template

```markdown
<Position, e.g. "Stack 2/5."> <One sentence on what this delivers.>

## Scope

- <Concrete change, with paths>
- <Data model as a table if there is one: field | type | notes>

## Out of scope

<What's excluded and which ticket owns it.>

## Decisions

<Only if the ticket depends on a decision made during planning: the decision and a short reason.>

## Done when

- Tests: <what they prove>
- <Environment>: <manual check>

## Setup (outside the diff)

- [ ] <Account / secret / variable / infra step, and where>
```

Leave out "Decisions" and "Setup" when they're empty. Security-relevant tickets say so on the first line and ask for the PR description to call it out.
