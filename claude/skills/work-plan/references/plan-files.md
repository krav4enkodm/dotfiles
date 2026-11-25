# The plan folder

The contract between `work-plan` and its phase skills. Each phase reads its inputs from these files, never from the conversation, and `scripts/plan.mjs` parses them, so the formats below are strict where the script reads them (marked **parsed**).

A plan lives in `~/work-work/plans/<slug>/`, outside every repo and the tracker, because one plan can span several repos.

```
~/work-work/plans/<slug>/
  state.json            written by `plan.mjs init` and `stamp`; never edit by hand
  input/concept.md      what the user asked for, verbatim, plus where the design is
  input/mockups/        mockup files the user handed over
  context/repo-<name>.md   recon, one per repo
  context/ui-inventory.md  recon, UI work only
  brief.md              what will be built: rules, examples, data map
  questions.md          every question a phase raised, and its answer
  decisions.md          assumptions a phase made instead of asking
  contracts.md          shapes that tickets share (feature and project only)
  README.md             the wave table
  NN-<slug>.md          one draft per ticket
  review/round-<n>/     the tickets as each review round saw them
```

## state.json

`slug`, `size`, `repos` (`[{ "name", "path" }]`), `design` (a Figma file key, `files`, or `none`), `phases` (the phases this plan runs, from its size) and `stamps` (per phase: when it was approved and a hash of each input). A phase is **stale** when an input changed after its stamp, or an earlier phase was stamped after it; `plan.mjs status` says which and why.

## Repo context: `context/repo-<name>.md`

Free form, with evidence as `path:line` or `package@version` for every claim:
stack and versions; the check commands; how this kind of change is laid out today (the closest similar feature, to copy); API conventions (routes, errors, pagination, auth); the design-system components in use; test style; anything that surprised you.

## UI inventory: `context/ui-inventory.md`

One entry per element the work adds or changes, nested as on screen. **Parsed:** each entry is a list item starting with its bold id.

```markdown
## Members page (frame 12-34)
- **U1** Header: team name, member count — node 12-35 — shows: team.name, team.memberCount
- **U2** Members list — node 12-40 — shows: member.name, member.role — states drawn: populated
  - **U3** Invite button — node 12-41 — drawn hovered — opens U4
- **U4** Invite modal — node 12-50

## Not on the mockups
- Loading, empty and error states of U2
- Resting look of U3 (the frame draws it hovered)
```

"shows:" names the data each element displays; the brief's data map starts from it. "Not on the mockups" lists what a static frame can't say (see [design.md](design.md)); each line becomes a fact, a decision or a question in the brief.

## Brief: `brief.md`

```markdown
# Brief: <title>

Goal: <one or two sentences>

## Flows
1. <who does what, in order>

## Rules and examples
- **R1** <behaviour the system must have, testable>
  - **E1** Given <state>, when <action>, then <outcome>.
  - **E2** <the edge or error case>

## Data map
| Element | Data | Source | Status | Evidence |
|---|---|---|---|---|
| U1 | team.name | GET /teams/:id | exists | `api/teams/routes.ts:42` |

## Facts found
- <something that looked like a question, answered from the code> — `path:line`

## Out of scope
- <what's excluded>
```

**Parsed:** rule and example ids (`- **R1**`, `- **E1**`), as list items. Status is `exists`, `change` or `new`. Mark an id `[out]` (e.g. `- **U5** Billing banner — [out] another plan`) to keep it in the record without a ticket.

## Questions: `questions.md`

```markdown
## Q3 · open · blocker · brief
<the question, naming what it decides>
Checked: <what the phase looked at before asking: files, nodes, docs>
Affects: R2, U4
Options:
- A (recommended): <option> — <consequence>
- B: <option> — <consequence>
Answer:
```

**Parsed:** the heading, `## <id> · <status> · <blocker|gap> · <phase>`. Status moves `open` → `answered` (the coordinator wrote the user's answer) → `applied` (the phase put it into its files), or to `deferred` (the user accepted the recommended option as a default for now). A phase can't be stamped, and the next one can't start, while any of its questions is `open` or `answered`.

## Decisions: `decisions.md`

Assumptions a phase made instead of asking, because the choice was low-impact and reversible: `- **D1** <decision> — <reason>`. The coordinator shows them at the brief and contracts gates so the user can overturn any of them. Answers given during review go into the tickets' Decisions sections, not here, so review doesn't make the earlier phases stale.

## Contracts: `contracts.md`

One section per shape that two tickets share. **Parsed:** the heading, `### C<n> · <name> · <api|type|props|schema|event|fixture>`.

```markdown
### C1 · Members API · api
Owner repo: api · Used by: web
Covers: R1, E1
<the shape: TypeScript types, an OpenAPI fragment or a JSON example; errors; auth>
```

A contract used across repos is written once here; each repo's contract ticket quotes it.

## Tickets: `NN-<slug>.md`

The template in [definition-of-ready.md](definition-of-ready.md). Numbered across the whole plan (01, 02…) even when it spans repos. **Parsed:** the first line (`Wave N.` or `Wave N · blocked by 01, 03.`), and within the first lines a `Repo: <name>` line (plans over several repos) and a `Covers: R1, E2, U3, C1` line (every plan with a brief).

## Wave table: `README.md`

**Parsed:** the first table whose header starts with `| Wave |`. One row per ticket; "Blocked by" is `—` or a comma-separated list of ticket numbers; "Changes" lists the main files or folders from the ticket's Scope in backticks. A path ending in `/` or a wildcard stands for everything under it; that is what the overlap check compares.

```markdown
| Wave | Ticket | Repo | Blocked by | Changes |
|---|---|---|---|---|
| 1 | 01 Members API contract | api | — | `api/members/schema.ts` |
| 1 | 02 Members types and fixtures | web | — | `web/src/members/types.ts` |
| 2 | 03 Members endpoint | api | 01 | `api/members/*` |
| 2 | 04 Members list section | web | 02 | `web/src/members/List/` |
```

The Repo column is required when the plan spans several repos and optional otherwise.

## What `plan.mjs check` enforces

- every row has a ticket file and every ticket file a row; first lines agree with the table;
- blockers exist, there is no cycle, and each wave is one after its latest blocker's;
- no two tickets in the same wave and repo list overlapping Changes;
- every R, E, U and C id not marked `[out]` is covered by a ticket, and tickets cover only defined ids;
- warns about fan-in (two or more blockers) anywhere but the last wave.
