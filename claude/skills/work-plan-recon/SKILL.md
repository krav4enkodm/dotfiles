---
name: work-plan-recon
description: Recon phase of work-plan; run only by the work-plan skill, with the plan folder as its argument. Maps each repo the plan touches and, for UI work, the design into context files. Never asks the user.
argument-hint: "<plan dir>"
user-invocable: false
context: fork
---

# Recon

Plan folder: `$ARGUMENTS`. File formats: `~/.claude/skills/work-plan/references/plan-files.md`.

Read `state.json` (repos, design) and `input/`. You map what exists; you decide and ask nothing. Write only inside the plan folder.

## 1. Each repo

For every repo in `state.json`, at the same time, start one `Explore` agent (thoroughness "very thorough") on that repo's path, with the concept, asking for:

- stack and versions (from the lockfile or installed packages, not memory), and the check commands (test, lint, typecheck) from the repo's agent docs and task runner;
- the code this work will produce or consume, and the closest similar feature to copy, with its layout;
- API conventions: routes, request validation, error shape, pagination, auth and access checks;
- the design-system components and tokens in use (UI repos);
- how tests reach this kind of code;
- deploy and CI flow, environments.

Every claim comes back with `path:line` or `package@version`. Write each result to `context/repo-<name>.md`, keeping the evidence. Note anything surprising: a convention the concept would break, a similar feature that already half exists.

## 2. The design (UI work only)

Skip if `state.json` says `"design": "none"` and `input/mockups/` is empty.

- **Figma:** pull each frame and node per "Pulling a node" in `~/.claude/skills/work-plan/references/design.md`.
- **Mockup files:** read every image in `input/mockups/`.

Write `context/ui-inventory.md`: every element the work adds or changes, nested as on screen, each with its U id, its node or mockup region, what data it shows (`shows:`), what it does, which states are drawn, and the design-system component that should render it, from the repo context. Then "Not on the mockups": every state and behaviour a static frame can't show (loading, empty, error, the resting look of a frame drawn hovered or open, elements on screen today that the mockup leaves out, what each control does). Don't resolve these here; the brief does.

Ids are stable: if `context/ui-inventory.md` already exists, keep the ids of elements that are still there and give new elements new numbers.

## Return

Exactly one line, then at most five lines of summary (repos mapped, element count, anything that will change the plan):

- `PHASE recon: DONE`
- `PHASE recon: FAILED <reason>` when a repo path doesn't exist or the design tool isn't reachable. Don't work around a missing source.
