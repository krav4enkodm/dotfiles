---
name: pr-review
description: Review a pull request or branch — someone else's or your own — against its ticket and the frontend and backend coding rules its files match, in a separate read-only reviewer so the diff never fills this conversation. Backend files also get a runtime pass (failures, retries, idempotency, races, data safety, rollout). Reports a verdict and findings by severity, each with its cost and a fix; never posts. Use when asked to "review this PR", "review PR 123", "review my branch", "/pr-review", or for a pre-merge review.
---

# PR review

You gather what the reviewer needs, start the `pr-reviewer` agent, and relay
its report. The agent does the review in its own context and finds the rules
that apply from the changed paths: `~/.claude/rules/` (the frontend rules and
the `backend-*` rules) plus the repo's own. You don't post anything on GitHub;
the user decides what to post.

## 1. Resolve the target

The user names one of:

- **nothing** → the current branch: base is
  `git merge-base HEAD origin/<default branch>`, head is `HEAD`.
- **a PR number or URL** →
  1. `gh pr view <n> --json number,title,body,url,baseRefName,headRefOid,headRepository,files`.
  2. If the current directory is a clone of the PR's repo:
     `git fetch origin <baseRefName> pull/<n>/head`, then base is
     `origin/<baseRefName>` and head is `headRefOid`. Fetching only adds
     objects; don't check anything out or touch the user's branch.
  3. If it is not, ask where the repo is cloned, or whether to clone it into
     the scratchpad.
- **a commit range or paths** → use them as given.

## 2. Gather intent

- The PR title and description (for a branch, its commit messages).
- The ticket, if one is linked or named in the title or branch and a tracker
  tool is available: its description and acceptance criteria. Say so if you
  couldn't reach it.
- Anything the user asked to focus on.

## 3. Run the reviewer

Start the `pr-reviewer` agent with: the repo path, the base and head refs, the
PR title and description, the ticket text, and the focus. Don't add your own
view of the change, so the review isn't anchored on it.

## 4. Relay the report

Show the agent's report as it came back. Then, in a line or two, say what to
look at first and anything the review couldn't cover (the ticket was
unreachable, files it couldn't read). If the user wants to reply on the PR,
draft the comments for them to post; don't post them.
