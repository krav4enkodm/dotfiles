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
- [ ] **UI work has a Design section** (below): every element the ticket adds or changes points to its design node, and everything the design can't show is written down.

## Design section (UI tickets)

The design file is the only source of visual values. The ticket says **where** to look and **what the design doesn't say**. It never copies sizes, colours, fonts or spacing into its text: a copy goes stale the moment the design changes, and the validator would then approve the stale value.

It holds three things:

- **Element map.** One line per element the ticket adds or changes: the element, its design node ID, and the design-system component expected to render it (e.g. "Submit button: 12-345, design-system `Button`"). Menus, popovers and other open states get their own node.
- **What the design can't show.** Decisions a static frame can't express:
  - which state a frame draws when it isn't the resting one (hover, active, open, selected, loading, disabled), and what the element looks like at rest;
  - existing elements the mockup leaves out, and whether they stay or go;
  - behaviour: what each control does, empty and loading states.
- **Allowed deviations.** Every place the build will knowingly differ from the design, with the reason.

The worker and the validator pull the actual values (design variables/tokens and what they resolve to) from these nodes at check time.

## Ticket template

```markdown
<Position, e.g. "Stack 2/5."> <One sentence on what this delivers.>

## Scope

- <Concrete change, with paths>
- <Data model as a table if there is one: field | type | notes>

## Design

<UI tickets only. Element map (element — design node ID — expected component), then what the design can't show (states, kept or removed elements, behaviour), then allowed deviations. Node IDs and decisions only; no copied values.>

## Out of scope

<What's excluded and which ticket owns it.>

## Decisions

<Only if the ticket depends on a decision made during planning: the decision and a short reason.>

## Done when

- Tests: <what they prove>
- Design (UI tickets): every element in the Design section matches its node in the running app; see the worker brief's design check.
- <Environment>: <manual check>

## Setup (outside the diff)

- [ ] <Account / secret / variable / infra step, and where>
```

Leave out "Design", "Decisions" and "Setup" when they're empty. Security-relevant tickets say so on the first line and ask for the PR description to call it out.
