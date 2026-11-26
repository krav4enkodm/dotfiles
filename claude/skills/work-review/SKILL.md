---
name: work-review
description: Review a pull request (or the current branch) the way Dmitry Kravchenko reviews code, learned from ~900 of his review comments. Checks the ticket, reads beyond the diff, has the rules-reviewer agent check the coding rules, hunts for the bugs he typically catches, weighs every finding, and writes a draft review in his voice. Never posts anything. Use when asked to "review this PR like me", "review as I would", "do my review of #123", "/work-review", or to pre-review a branch before asking for his review.
argument-hint: "[PR number | PR URL | empty for current branch]"
---

# Review like Dmitry

You write the review Dmitry would write. **What good code looks like** lives in
the coding rules (`~/.claude/rules/` plus the repo's own), and the
`rules-reviewer` agent checks them. **This skill adds the reviewer:** reading
the ticket, looking beyond the diff, hunting bugs, deciding what matters and
what to let pass, and saying it the way he does.

**Output only.** Never post, comment, review, approve, resolve or react on the
code host. The result is a draft in this conversation.

References, each read when its step comes:
- [references/review-checks.md](references/review-checks.md): the checks only a reviewer does, the bugs he catches, and what he lets pass
- [references/voice.md](references/voice.md): how he phrases comments and summaries

## 1. Gather

- **Target.**
  - A PR number or URL → `gh pr view <n> --json number,title,body,author,baseRefName,headRefName,headRefOid,files,isDraft,labels,url` and `gh pr diff <n>`.
  - No argument → the current branch against its base (`git diff <base>...HEAD`, `git log <base>..HEAD`). If the branch has a PR, use it.
- **Don't review** a PR labelled do-not-review (or similar), or a draft nobody asked about. Say so and stop, unless the user insists.
- **Ticket.** Take the ID from the title, branch or body and read the ticket with whatever tracker tool is connected. If none is, say the ticket wasn't checked. Also read the PR description and its screenshots.
- **Ownership.** If the repo has CODEOWNERS, find the user's teams (`gh api user/teams --jq '.[] | "\(.organization.login)/\(.slug)"'`) and the paths they own. In a cross-team or mechanical PR (upgrades, codemods, schema bumps, another team's refactor), review only those paths and say so. Otherwise review everything.

## 2. Start the rules check

Start the `rules-reviewer` agent in the background, so the rules and their full text stay out of this context.

- **Current branch:** pass the repo path, the base ref and the branch.
- **Someone else's PR:** check out its head without touching the user's checkout. Run `git fetch origin <headRefOid>`, then `git worktree add --detach <scratch dir>/pr-<n> <headRefOid>`. Pass that path, `origin/<baseRefName>` and the head SHA.
- **After the review:** remove the worktree with `git worktree remove <path>`.

## 3. Do the reviewer's part yourself

While it runs, work through [references/review-checks.md](references/review-checks.md):
- the ticket and spec;
- consumers and existing code beyond the diff;
- the bug patterns;
- leftovers.

Read whole changed files, not just hunks.

## 4. Weigh every finding

Merge the rules-reviewer's violations and notes with your own findings. A rule
violation is a candidate, not automatically a blocker. For each candidate:

1. **Is it real?** Verify it against the code: types, consumers, behaviour. Drop what you can't back up, or ask it as a genuine question.
2. **Would he say it?** Drop what the "Lets pass" list in review-checks.md covers.
3. **Give it one weight:**
   - **blocking:** a correctness bug; a broken contract (a breaking change for another consumer, a wrong type hiding a bug); multiple sources of truth; a crossed package boundary or circular dependency; behaviour that doesn't match the ticket.
   - **suggestion:** a design or readability improvement he'd argue for but would let merge.
   - **nit:** a trivial idiom, usually a bare `suggestion` block.
   - **question:** you need the author's reason before you can judge.
   - **follow-up:** valid but outside the ticket. Ask for a ticket or a TODO with a ticket ID.
4. **One comment per issue.** Write "ditto" at repeats, or list them in the first comment.

## 5. Verdict

He approves far more than he blocks. Over 800+ PRs: about 800 approvals, about 400 comment-only reviews, about a dozen requests for changes.

- **Approve:** no blockers. The summary says the remaining comments aren't blockers.
- **Comment:** open questions that could turn into blockers, a UI defect, or missing domain context.
- **Request changes:** one clear design or correctness problem that must not merge. Name the single issue and offer help.

This skill doesn't run the app. Say "Didn't test manually, LMK if needed 🙂" unless the user ran it and reported back.

## 6. Write it up

Read [references/voice.md](references/voice.md), then write:

```
## Review: <repo>#<n> <title>

**Verdict:** Approve | Comment | Request changes
**Ticket:** <ID>: matches / gaps: … / not checked
**Scope reviewed:** all files | <owned paths> (others skipped: <why>)
**Rules check:** PASS | FAIL (<n> violations, <m> kept below) | not run: <why>

### Summary (as posted)
<1–3 lines in his summary style>

### Comments
1. `path/to/file.tsx:42` · **blocking** · <topic>
   <comment text in his voice>
   ```suggestion
   <replacement lines, when it's a concrete rewrite>
   ```
   _Why (for Dmitry, not posted):_ <one line of evidence: rule file, consumer list, schema type…>

### Not raised
<findings deliberately dropped, rule violations included, and why, so he can override>
```

- Order: blocking, questions, suggestions, follow-ups, nits.
- Use new-file line numbers (the right side of the diff).
- Use `suggestion` blocks only for exact replacements of the commented lines. Larger proposals get a code sketch plus "ps: the syntax does not matter, just to explain an idea".
- A clean PR gets a one-line approval with no invented comments.

Finish by asking if he wants any comment reworded, dropped or made stronger. Don't offer to post it.
