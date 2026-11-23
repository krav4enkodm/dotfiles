---
name: work-retro
description: Retro of one ticket worked by work-work, run in that ticket's worker pane after its PR merged. Collects every point where the user had to step in (their messages in the pane, decisions added to ticket.md while it was worked, PR review comments), finds what the setup should have known instead, and turns each into a proposed fix. Fixes for the project's own instructions are applied on request; fixes for the dotfiles repo skills go to an inbox that work-retro-apply turns into a PR. Runs only as /work-retro.
argument-hint: "[worktree path]"
disable-model-invocation: true
---

# Ticket retro

A ticket that went through `work-work` with no input from the user is the target. Every time the user had to step in, the setup (the ticket, the brief, the validator, the rules reviewer, the project's instructions) was missing something. This skill finds each of those moments and names the fix, so the next ticket needs less.

Run it in the ticket's worker pane, after the PR merged. It reads; it changes nothing until the user says which fixes to apply.

## 1. Collect

Run these and keep the output; don't read the raw transcripts.

- **The pane.** `bash ~/.claude/skills/work-retro/scripts/interventions.sh` (pass the worktree path if you're not in it). It prints the session as a timeline of tagged entries and the `workspace:` folder. `you`, `rejected` and `interrupted` entries are the user stepping in. `coordinator` entries are context only: the user's answers that reached the worker that way are recorded in `ticket.md`. `blocked` entries are friction from hooks, permission rules or the auto-mode classifier. `worker asked` entries are the worker's `BLOCKED` questions: each one is an intervention even if its answer never reached Decisions. A question about the environment (no browser, no login, no app slot) belongs to Coordinator or Setup, not to the ticket.
- **The ticket as worked.** `<workspace>/ticket.md`, Decisions and Scope. Count a decision only if it was made during the work: it names a source or a date ("— user, 2026-11-04", "from review", "answer to the worker's question"). Untagged decisions date from planning.
- **Validation.** Any validator or rules reviewer FAIL rounds recorded in the workspace (`validation*.md`, `fix-round-*.md`) or in `coordinator` entries: how many rounds, and which gaps.
- **The PR.** `gh pr view --json number,url,state,comments,reviews` for the branch, and the inline review comments: `gh api repos/{owner}/{repo}/pulls/<number>/comments --jq '.[] | {path, line, body}'`. If the PR isn't merged yet, say so and ask whether to go on; later review would be missed.

## 2. Find what was missing

Make one list of interventions from all sources, oldest first. When the same point shows up twice (a review comment and the decision it led to), keep it once. For each, answer: **what did the user have to say that the setup should have known?** Then put it in one bucket:

| Bucket | Sign | Where the fix goes |
|---|---|---|
| Ticket: missing | The ticket didn't say it: a missing state, a behaviour, an edge case, a design detail | `work-plan`: usually a line in [definition-of-ready.md](../work-plan/references/definition-of-ready.md) or [review-checklist.md](../work-plan/references/review-checklist.md) that would have made planning ask |
| Ticket: unclear | The ticket did say it, but the worker read it another way, asked about it, or missed it: it was vague, abstract, buried in prose, or contradicted elsewhere in the ticket | `work-plan`: how tickets are written (the template in [definition-of-ready.md](../work-plan/references/definition-of-ready.md), the drafting steps in [SKILL.md](../work-plan/SKILL.md)); the fix usually cuts or sharpens text rather than adding it |
| Worker | The worker did something the brief or the instructions already rule out, or missed a step of the brief | [worker-brief.md](../work-work/references/worker-brief.md); a hook or deny rule if prose has already failed (see "Which Claude Code feature holds what" in the dotfiles repo's `docs/decisions.md`) |
| Validator | The validator passed something the user then caught | the [ticket-validator](../../agents/ticket-validator.md) agent, or [design.md](../work-plan/references/design.md) for design checks |
| Rules reviewer | The code broke a rule that already exists, and the rules reviewer passed it: missed the rule file, judged it a note, or didn't look | the [rules-reviewer](../../agents/rules-reviewer.md) agent; if its "Rules considered" table didn't list the rule, how it finds rules. A rule broken again and again is better enforced by the repo's linter: say so under Project |
| Coordinator | Something about how the run was driven: start order, rebases, the app slot, messages to the worker | the `work-work` skill |
| Setup | A `blocked` or `rejected` entry that keeps happening, a permission prompt | `settings.json` permissions or a hook |
| Project | A convention or fact about this codebase: a helper to reuse, a pattern, a command | this repo's own CLAUDE.md / AGENTS.md / rules, not the dotfiles repo |
| None | Taste, a one-off, a question the user asked out of interest, a request beyond the ticket | nothing |

To tell the two ticket buckets apart, check the ticket text (as planned, not the amended Decisions) for the point the user made. Found it there → unclear; quote the ticket line next to the user's words. Not there → missing.

Read the user's messages carefully: a question ("why did you use X here?") is often a correction in disguise, and "looks good" closes a loop. Validator and rules reviewer FAIL rounds the worker fixed alone are not interventions, but two or more rounds on the same kind of gap point at the brief or the ticket.

## 3. Report

If nothing landed in a bucket other than None: say "<ticket> went through clean" and stop.

Otherwise, list each intervention:

```
1. «<the user's words, or the review comment>»  (pane | ticket.md | PR)
   Missing: <what the setup should have known, one sentence>
   Fix: <file> → <the change, specific enough to apply>   [dotfiles | project]
```

Then the None items in one line. Propose only fixes the evidence supports, and prefer changing or removing a line over adding one.

## 4. Apply

Ask which fixes to keep.

- **Project fixes**, applied here on the user's OK: fetch, branch off the default branch (the ticket's branch has merged), edit the repo's instructions, commit with the `commit` skill and open a draft PR with `open-pr`.
- **Dotfiles fixes** are never applied from here: they belong in the dotfiles repo, not this one. Append the kept ones to `~/work-work/retros/inbox.md` in the format in [inbox-format.md](references/inbox-format.md), and say they're there for `/work-retro-apply` in the dotfiles repo.
