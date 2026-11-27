---
name: work-clean
description: Remove the herdr worktrees whose pull requests have merged. Finds every linked worktree of the repos open in herdr, looks up its branch's PR on GitHub, and for each merged one removes the checkout, closes its herdr workspace and deletes the local branch, skipping anything that would lose work. Use when the user asks to clean up merged worktrees or tidy up after work-work.
argument-hint: "[repo path ...] [--dry-run]"
disable-model-invocation: true
---

# Clean up merged worktrees

`work-work` leaves every ticket's worktree and worker running, because the user reviews and iterates through them. Once a PR merges, its worktree is dead weight. This skill removes those, and only those.

A worktree is removed when all of these hold, and kept otherwise:

- its branch has a **merged** PR and no open one;
- its working tree is **clean** (`git status --porcelain` is empty);
- it has **no commits beyond the merged PR**: its `HEAD` is the PR's head commit or an ancestor of it;
- no agent in its workspace is **working**, since closing the workspace kills its panes;
- it isn't the checkout **this session runs in**.

Never pass `--force` to a removal, and never touch a repo's main checkout.

## Steps

1. **Check herdr.** `test "${HERDR_ENV:-}" = 1`. If it fails, say this skill must run inside herdr and stop.
2. **Collect the worktrees.** `herdr workspace list` gives every open workspace; the ones with a `worktree` field name their repo in `worktree.repo_root`. With repo paths as arguments, use only those repos. For each repo, `herdr worktree list --cwd <repo_root>` lists all its git worktrees, including linked ones with no open workspace (`open_workspace_id` null). Keep the entries with `is_linked_worktree: true`. A detached or prunable one has no branch to look up: list it as kept, with the reason.
3. **Look up each branch's PR**, from the repo root: `gh pr list --head <branch> --state all --json number,state,url,headRefOid,mergedAt`. Any `OPEN` PR → keep. Otherwise the most recent `MERGED` one decides; none merged (no PR, or only closed ones) → keep.
4. **Check the merged ones** against the list above, in the worktree:
   - `git -C <path> status --porcelain` is empty;
   - `git -C <path> rev-parse HEAD` equals `headRefOid`; if not, `git -C <repo_root> fetch origin pull/<number>/head` and `git -C <path> merge-base --is-ancestor HEAD <headRefOid>` must succeed. This works for squash merges too, where `git branch -d` would refuse;
   - the workspace's `agent_status` in `herdr workspace list` isn't `working`;
   - `$PWD` isn't inside the worktree path.
5. **Show the table** before touching anything: repo, worktree label, branch, PR (link and state), and the action, `remove` or `keep: <reason>`. With `--dry-run`, stop here.
6. **Remove** each `remove` row, one at a time:
   - With an open workspace: `herdr worktree remove --workspace <open_workspace_id>`. It removes the checkout and closes the workspace, and refuses a dirty tree (`dirty_worktree_requires_force`): if it does, keep the row and say so.
   - Without one: `git -C <repo_root> worktree remove <path>`.
   - Then `git -C <repo_root> branch -D <branch>`. `-D` because a squash-merged branch never looks merged to git; step 4 already proved nothing on it is lost.

   Read each result; if a command fails, record the error on that row and carry on with the rest.
7. **Report** the table again with the outcome per row: removed, kept (and why), or failed (and the error). Name the worktrees kept only because of uncommitted changes or extra commits, so the user can look at them.

## Rules

- **Leave everything else alone:** remote branches, the `~/work-work/` ticket folders and `batch.md`, the main checkout, and worktrees whose PR isn't merged.
- **Never force.** A refusal from git or herdr means there's work to lose; report it, don't retry with `--force`.
- **Read IDs from herdr's JSON.** Never guess a workspace ID from a label or the sidebar order.
