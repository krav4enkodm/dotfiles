---
name: work-retro-apply
description: Turn the workbench fixes collected by work-retro (in ~/work-work/retros/inbox.md) into one draft PR against this repo. Groups the findings, shows how often each came up and whether an earlier fix failed to hold, applies the ones the user picks in generic wording, and moves them to applied.md. Runs only as /work-retro-apply, inside the workbench repo.
disable-model-invocation: true
---

# Apply retro findings to the workbench

`work-retro` runs in a ticket's worker pane and leaves the fixes meant for the workbench in `~/work-work/retros/inbox.md` ([format](../../../claude/skills/work-retro/references/inbox-format.md)). This skill turns them into a PR here. It's the only place those findings become changes: the repo stays the source of truth, and `./install.sh` rolls the merged change out.

## Steps

1. **Read** `~/work-work/retros/inbox.md` and `~/work-work/retros/applied.md`. If the inbox is empty or missing, say so and stop.
2. **Group** the entries that point at the same gap, even when worded differently or found in different projects. For each group: the bucket, the target file, how many tickets it came from, and the quotes. If a group matches something in `applied.md`, mark it **recurred after <PR>**: that fix didn't hold, so propose a stronger one (a checklist item instead of a sentence, a hook instead of prose) rather than the same text again.
3. **Check each fix against the current file.** Read the target in `claude/`; the skill may have changed since the retro. Drop or rework fixes that are already covered.
4. **Show the groups**, most tickets first, recurred ones on top, each with the proposed change. Ask which to apply. Groups not picked stay in the inbox; drop an entry only when the user says so.
5. **Apply** the picked ones on a branch off `main`:
   - Write the change in generic terms. Quotes, ticket keys, project names, internal packages and URLs from the inbox stay out of the files, the commit and the PR (see "Keep it publishable" in CLAUDE.md).
   - Keep README.md and the "Depends on" columns in step, and every `work-plan/references/` reference if a file moves.
   - Prefer changing or removing a line over adding one.
   - Run `./check.sh`, commit with the `commit` skill (the body says which problem kept coming up and how often), and open a draft PR with `open-pr`.
6. **Move** the applied entries from `inbox.md` to `applied.md`, each with `  Applied: <PR url>`.

Don't run `./install.sh`: install from `main` after the PR merges.
