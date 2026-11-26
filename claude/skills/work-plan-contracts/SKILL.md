---
name: work-plan-contracts
description: Contracts phase of work-plan; run only by the work-plan skill, with the plan folder as its argument. Fixes the shapes that parallel tickets will share — API requests and responses, shared types, view-models, component props, schema fields, fixtures — before any ticket is drafted. Never asks the user.
argument-hint: "<plan dir>"
user-invocable: false
context: fork
---

# Contracts

Plan folder: `$ARGUMENTS`. File formats: `~/.claude/skills/work-plan/references/plan-files.md`.

Read `brief.md`, `decisions.md`, `questions.md` and everything in `context/`. Write only `contracts.md`, `questions.md` and `decisions.md`.

Contracts are what let tickets run in parallel: once a section's props and a page's data shape are fixed, the section, the data fetching and the API can be built side by side, each against the contract and fixtures, and wired together at the end.

## If answers are waiting

Apply `answered` questions from phase `contracts` first, as the brief phase does: change `contracts.md`, set them to `applied`, add follow-ups.

## Find the boundaries

List every place two pieces of the work will meet:

- **API:** each endpoint the data map marks `new` or `change`: method, path, request, response, errors, who may call it.
- **Shared types and view-models:** the shape a screen receives, assembled from one or more endpoints.
- **Component props:** for each inventory element big enough to be built on its own (a section, a modal), the props it takes and the events it emits, so the section and the page that assembles it agree.
- **Schema fields, events, config** that one piece writes and another reads.
- **Fixtures:** example data for each shape, covering the brief's examples (empty, one, many, error), so UI work doesn't wait for the API.

## Write each contract

- Follow the repo's existing conventions from `context/repo-<name>.md`: extend the types and error shapes it already has rather than inventing parallel ones. Check each existing shape you extend in the code and cite it.
- Write the shape concretely: TypeScript types, an OpenAPI fragment, or a JSON example, whichever the owner repo uses.
- Give each one its owner repo (where it is defined), the repos that use it, and the brief ids it serves (`Covers:`).
- A contract used across repos is written once. Each repo will get its own contract ticket that quotes it; note how the consuming repo gets the shape today (generated client, hand-written types, a shared package).
- Ids are stable across runs.

Unknowns go the same three ways as in the brief: a fact from the code, a question (phase `contracts`), or a decision. Typical questions: who computes a derived value (client or server), pagination, how errors reach the user.

## Return

Exactly one line, then one line per contract (id, name, owner → users):

- `PHASE contracts: NEEDS-ANSWERS <n>` when any question from phase `contracts` is `open`;
- `PHASE contracts: DONE` otherwise.
