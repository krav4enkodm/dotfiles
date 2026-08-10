---
name: commit
description: Commit the current changes following the conventions of the repo you're in — detected from its own history — with a concise title of WHAT changed and a body explaining WHY the change was made / why this approach was chosen, distilled from the conversation. Use when the user asks to commit, "/commit", "commit these changes", "make a commit", or similar.
---

# Commit

Create a git commit for the current work. Two rules govern everything below:

1. **The repo decides the format.** Never assume a convention — read it out of `git log` and match it.
2. **The conversation decides the content.** The title says *what* changed; the body explains *why* it changed and why this approach, condensed from how we arrived at it.

## Procedure

1. **See what will be committed.** Run `git status` and `git diff` (and `git diff --staged`). Commit the changes from the work we just did. Don't blindly `git add -A` if unrelated changes are present — stage only what belongs to this change. If it's ambiguous what to include, ask.

2. **Detect the repo's conventions.** Run `git log --format='%s' -30` and read what's actually there. Identify:
   - **Title shape** — which of these dominates:
     - `[TICKET-123] Concise title` — bracketed issue key
     - `TICKET-123: Concise title` — prefixed issue key
     - `feat(scope): concise title` — Conventional Commits
     - `Concise title` — plain imperative, no reference
   - **Whether titles carry an issue reference at all.** A ticket in the *branch* name does not mean it belongs in the *title* — many repos keep it in the branch and PR only. Check the titles, not the branch.
   - **Whether bodies are used.** `git log --format='%b' -20` — if this repo's commits are title-only, keep yours brief too.
   - **Trailing `(#123)`** — if most titles end this way, it's the forge's squash-merge artifact, added automatically on merge. **Never type it yourself.**

   Follow what you find. The rest of this skill describes how to fill in the shape you detected.

3. **Find the issue reference — only if step 2 showed the repo uses one in titles.** In priority order:
   - **Branch name** (primary): `git branch --show-current`, then take a leading issue key matching `^[A-Za-z]{2,10}-[0-9]+` and **uppercase** it. Examples: `proj-412-investigate-…` → `PROJ-412`; `bill-7223-bulk-pay-…` → `BILL-7223`.
     - **Guard against false positives.** Only treat it as an issue key if that prefix also appears in recent commit titles (or the user confirms it). Branches like `node-18-migration` or `sidekiq-6-upgrade` match the pattern but mean nothing — don't turn them into `NODE-18`.
   - **Branch's own commits** (fallback): `git log --format='%s' origin/HEAD..HEAD` and reuse the reference they already use.
   - If the branch genuinely has no reference and history has none, commit **without** one. When unsure, ask rather than invent.

4. **Write the title.** Concise, capitalized, imperative-ish, no trailing period. Describe the change, not the files. Match the shape from step 2 exactly — including whether an issue key appears and how it's delimited.

5. **Write the body (the WHY) — concise.** A short paragraph (≈2–5 lines, wrapped ~72 cols) capturing the *reasoning* we reached in the conversation: the problem, why we chose this approach, any tradeoff or thing we ruled out. Not a list of what changed (the diff shows that). Keep it minimal and to the point.
   - Skip the body entirely for trivial/mechanical changes where the title is self-explanatory, or where step 2 showed this repo doesn't use bodies.

6. **Commit.** Use a HEREDOC so the body formats correctly:
   ```bash
   git commit -m "$(cat <<'EOF'
   Concise title in the repo's detected format

   Why this change was made and why this approach, condensed from the
   discussion that led here.
   EOF
   )"
   ```

7. **Respect the guardrails.**
   - Only commit when asked (invoking this skill is the ask). Don't push unless the user asks.
   - If on the repo's default branch, create a branch first, then commit. Resolve it rather than
     assuming: `git symbolic-ref --short refs/remotes/origin/HEAD`. That command *errors* when
     `origin/HEAD` isn't set (common on fresh clones) — fall back to whichever of `master` / `main`
     exists locally.

8. **Confirm.** Show the result with `git log -1 --stat` so the user sees the title, body, and files.

## Examples

Each matches a different detected convention. The body discipline is identical in all of them.

**Bracketed issue key** — branch `proj-412-investigate-flaky-artifact-uploads`, after deciding to cap the upload step:

```
[PROJ-412] Cap the screenshot upload step with a 2-min timeout

The upload step globs the whole artifacts tree, which walks a symlinked
dependency directory and intermittently stalls until the 60-min job
limit. Healthy uploads finish in under 35s, so a 2-min cap fails fast
instead of burning the entire job. Stop-gap; the real fix is to stop
globbing the symlinked tree.
```

**No key in the title** — branch `data-318-fix-phone-masking`, but this repo's history keeps the reference in the branch only:

```
Fix phone number masking for prefixed values

Numbers stored with a country prefix slipped past the matcher, so a
subset of records round-tripped unmasked. Widened the pattern rather
than normalizing on write, which would need a backfill of existing rows.
```

**Conventional Commits** — where `git log` shows `feat:`/`fix:`/`chore:` prefixes:

```
fix(auth): refresh the session token before it expires

Tokens were refreshed on the first 401, so every expiry cost one failed
request and a visible reload. Refreshing at 90% of TTL trades a cheap
background call for that user-visible failure.
```
