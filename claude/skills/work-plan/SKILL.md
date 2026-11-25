---
name: work-plan
description: Turn an idea, feature, project, or rough ticket into ready-to-implement tickets, grounded in the codebase, across one or more repos. One command leads through the phases — recon, brief, contracts, split, review — asks the user every question, stops for approval at each gate, and keeps the plan on disk so it can be resumed, inspected or re-run from any phase. Use when the user asks to plan, scope, break down, or ticket some work, asks "is this ticket ready?", or wants to make existing tickets ready to implement. Not for implementing the work itself.
argument-hint: "[what to build | <plan slug> [status | redo <phase>] | ticket IDs to check]"
---

# Plan work to ready-to-implement

The output is a set of tickets that each meet the Definition of Ready in [references/definition-of-ready.md](references/definition-of-ready.md), linked into waves so `work-work` can build as much as possible at once.

This skill is the **coordinator**. It runs each phase as its own skill in a forked context, talks to the user, and stops at the gates. It does no phase work itself, so its own context stays small over a long plan.

## Principles

- **Understand before splitting.** The user approves what will be built (the brief) and the shapes tickets share (the contracts) before any ticket is drafted. A wrong understanding is cheapest to fix there.
- **Investigate before asking.** A phase asks only what the code, the design and the docs can't answer, and each question says what it checked. Facts the code settles are fixed and reported, not asked.
- **Only the coordinator talks to the user.** Phases write questions to `questions.md` and return. You ask, record the answers, and run the phase again to apply them.
- **The plan lives on disk.** Every phase reads its inputs from the plan folder ([references/plan-files.md](references/plan-files.md)), never from this conversation. The user can edit any file directly; later phases go stale and run again.
- **Gates are counted, not judged.** Whether a phase can start or be approved is decided by `plan.mjs`, never by how ready the plan feels.
- **Ask well.** Questions follow [references/interview-rules.md](references/interview-rules.md).

## The script

`node ~/.claude/skills/work-plan/scripts/plan.mjs <command> <plan dir>`, called `plan.mjs` below:

| Command | Does |
|---|---|
| `init <dir> --slug <s> --size <task\|feature\|project\|tickets> --repo <name>=<path>... [--design <src>]` | Creates the folder and `state.json` |
| `status <dir>` | Each phase pending / done / stale (and what changed), unresolved questions, `next:` |
| `gate <dir> <phase\|publish>` | Exit 1 with the reasons if that step can't start yet |
| `stamp <dir> <phase>` | Records the phase as approved; refuses while its questions are unresolved or, for split and review, while `check` fails |
| `check <dir>` | Tickets and wave table: waves, cycles, overlap inside a wave, coverage of the brief, inventory and contracts |
| `resize <dir> <size>` | Changes the size, and with it the phases; stamps are kept |

## Phases

| Phase | Skill | Writes | Gate |
|---|---|---|---|
| recon | `work-plan-recon` | `context/repo-<name>.md`, `context/ui-inventory.md` | none: stamp when it returns DONE |
| brief | `work-plan-brief` | `brief.md`, `questions.md`, `decisions.md` | the user approves the brief |
| contracts | `work-plan-contracts` | `contracts.md` | the user approves the contracts |
| split | `work-plan-split` | `NN-<slug>.md`, `README.md` | `check` passes |
| review | `work-plan-review` | fixes in the tickets, `questions.md` | a clean review; the user approves the wave table |
| publish | this skill | tickets in the tracker | the user confirms once |

Which phases run depends on the size (set at `init`):

- **task** (one PR, one ticket): recon, brief, split, review. The brief is a paragraph and a few examples.
- **feature** (2–4 PRs) and **project** (5+ PRs, often several waves wide): all five.
- **tickets** (the user hands over existing tickets to make ready): review only.

## Starting

The argument decides:

- **Something to build → a new plan.**
  1. Size it in one line (above). If it grows or shrinks later, `plan.mjs resize <dir> <size>`.
  2. Find the repos it touches: the current one, plus any the work clearly needs (a frontend and its API). Ask for the path of a repo you can't find; never guess one.
  3. Pick a short slug and run `plan.mjs init ~/work-work/plans/<slug> ...`, with `--design <figma file key>` or `--design files` for UI work.
  4. Write the request verbatim to `input/concept.md`, with any links. Copy mockup files the user gave into `input/mockups/`. If the user only described mockups, ask them to drop the files in and wait.
- **A plan slug → resume.** Run `status` and continue the loop from `next:`.
- **`<slug> status`** → show the `status` output and the unresolved questions, and stop.
- **`<slug> redo <phase>`** → run that phase again; the phases after it go stale on their own.
- **Existing tickets ("is this ready?")** → `init --size tickets`, save each ticket's text as `NN-<slug>.md` with a wave table derived from its links (as in `work-plan-split`), writing blockers on first lines as draft numbers, and continue with review. When published, patch the changed sections of the existing tickets instead of creating new ones.

## The loop

1. `plan.mjs status <dir>`. The phase on the `next:` line is the one to run; `publish` means every phase is done.
2. `plan.mjs gate <dir> <phase>`. If it's closed, deal with what it names: an earlier phase that's stale (run it), or unresolved questions (ask them, below).
3. Tell the user in one line which phase is starting, then run it with the Skill tool: the phase's skill, with the plan folder as its argument. It returns one line, `PHASE <name>: DONE`, `NEEDS-ANSWERS <n>`, `AGAIN` (review only: run another round) or `FAILED <reason>`, and a short summary.
4. **NEEDS-ANSWERS:** ask the questions (below), then run the same phase again; it applies the answers and may raise follow-ups. **AGAIN** counts as a round too. After **3** rounds in one phase with questions or findings still open, list them and let the user choose per question: defer it with the recommended option as its default (set it to `deferred`), or keep going.
5. **FAILED:** show the reason and what the user can do about it (a repo path, a design tool that isn't connected). Don't work around it.
6. **DONE:** hold the phase's gate (below). On approval, `plan.mjs stamp <dir> <phase>` and go back to 1. If the user asks for changes, either edit the file yourself when the change is small and exact, or run the phase again with their words appended to `questions.md` as an `answered` question. Both make the right phases stale.

## Gates

Each gate shows one screen at most and points to the files for detail. Ask with the question tool: approve, or what to change.

- **brief:** the goal in two sentences; the flows; the data map (element → data → exists / change / new); how many facts were found in the code; every decision from `decisions.md` with its id, so the user can overturn one by id.
- **contracts:** one line per contract: id, name, owner repo, used by. New decisions with their ids.
- **split:** no user gate. If `stamp` refuses, run the split again with the `check` output; it fixes its own tickets.
- **review:** the wave table (with the Repo column for several repos), decisions made during review, and anything deferred.

## Asking

Read the phase's `open` questions from `questions.md`. Ask them per [references/interview-rules.md](references/interview-rules.md): blockers before gaps, highest impact first, up to four per question-tool call, recommended option first, each question naming the ticket or brief item it decides. Write each answer under the question's `Answer:` line and set its status to `answered`. If the user doesn't understand a question, re-explain it with a concrete scenario as the rules say, then ask again.

## Publish

1. `plan.mjs gate <dir> publish` must be open.
2. Create the tickets per [references/trackers.md](references/trackers.md), including its rules for plans over several repos. Confirm titles, repos, waves and the container in one message, then create the tickets and their blocked-by links, put the wave table in the container, and replace the draft numbers on first lines and in the table with the tracker's ids. A task needs no container or table: its one ticket says "Wave 1."
3. Report: the wave table with links, the decisions made, anything deferred.

## Done

Every ticket meets the Definition of Ready, the last review was clean, and the user has the links. Suggest running the plan with `/work-work <container>` (the plan folder, for markdown tickets), or `/work-work <ticket id>` for a task. For a plan over several repos, `work-work` runs in each repo on that repo's tickets; a ticket blocked by one in another repo starts once that one has merged. `work-work` only runs when the user types it, so don't invoke it, and don't start implementing unasked.
