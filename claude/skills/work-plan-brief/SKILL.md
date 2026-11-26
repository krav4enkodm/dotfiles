---
name: work-plan-brief
description: Brief phase of work-plan; run only by the work-plan skill, with the plan folder as its argument. Writes what will be built — flows, rules with examples, a data map checked against the code — and records every unknown as a fact, a decision or a question. Never asks the user.
argument-hint: "<plan dir>"
user-invocable: false
context: fork
---

# Brief

Plan folder: `$ARGUMENTS`. File formats: `~/.claude/skills/work-plan/references/plan-files.md`.

Read `input/concept.md`, everything in `context/`, `questions.md` and `decisions.md`. Write only `brief.md`, `questions.md` and `decisions.md`. The user reads the brief to check that you understood the work, so write it for them: short, concrete, in their terms.

## If answers are waiting

If `questions.md` has `answered` questions from phase `brief`, apply each one first: change `brief.md` (and `decisions.md` if the answer overturns a decision), set the question to `applied`, and add any follow-up question the answer opens. Then run the rest of this skill only where the answers changed something.

## Write the brief

1. **Goal**, in one or two sentences, in your own words.
2. **Flows**: who does what, in order, including what happens on failure.
3. **Rules and examples** (Example Mapping). One rule per behaviour the system must have, each testable. Under each rule, concrete examples in Given/When/Then: the main case, then the edge and error cases. A rule you can't give an example for isn't understood yet: that's a question. The examples become the tickets' "Done when", so make them checkable.
4. **Data map**: for each inventory element that shows data, and each rule that needs data, the field, where it comes from, and whether it exists, needs a change, or is new. Check every row in the code: open the actual route, serializer, query or type, and give `path:line`. A field that exists under a different name or shape is a `change`.
5. **Facts found**: things that looked like questions but the code, the design or the docs answered, each with evidence.
6. **Out of scope**: what's excluded. Inventory items that belong elsewhere get `[out]` with the reason.

Ids are stable across runs: keep the ids of rules and examples that are still there; new ones get new numbers.

## Every unknown goes one of three ways

Work through "Not on the mockups", every rule without examples, every `new` or `change` row in the data map, and anything the concept leaves open:

- **The code, design or docs answer it** → it's a fact. Fix the brief and list it under "Facts found". Read the installed source for library behaviour, never memory.
- **A real choice that changes behaviour users see, the data model, access, a contract or the split** → a question in `questions.md`: `open`, `blocker` (or `gap` if a sensible default exists), phase `brief`, with what you checked, what it affects, and 2–4 options with a one-line consequence each, the recommended one first.
- **A low-impact, reversible choice** → a decision in `decisions.md` with its reason (e.g. which existing empty-state component to reuse). The user sees every decision at the gate and can overturn it.

Never invent an answer and present it as a fact.

## Return

Exactly one line, then at most five lines of summary (rules, examples, data rows by status, facts, decisions):

- `PHASE brief: NEEDS-ANSWERS <n>` when any question from phase `brief` is `open`;
- `PHASE brief: DONE` otherwise;
- `PHASE brief: FAILED <reason>` when the context files are missing (recon didn't run).
