---
name: open-pr
description: Open a GitHub pull request (or rewrite an existing one's description) with a focused, concise description written for other engineers, following the repo's PR template when one exists and adding a Mermaid diagram when it makes the change easier to understand. Use when the user asks to open, create, or raise a PR, or to write, draft, or improve a PR description.
argument-hint: "[base branch or PR number]"
---

# Open a PR

The output is a PR whose description a reviewer can read in under two minutes and come away knowing what changed, why, and where to look.

New PRs are always **drafts**, and the skill doesn't stop for confirmation: the draft is where the user reviews it. Create a ready-for-review PR only when the user asks for one.

## 1. Gather the change

- Stack check: if the `gh stack` extension is installed (`gh extension list`) and the branch sits on another feature branch rather than the default branch, follow [Stacks](#stacks) alongside the steps below.
- Base branch: the argument if given; in a stack, the branch directly below this one; otherwise the repo's default branch (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`).
- Read `git log <base>..HEAD` and `git diff <base>...HEAD`. Read the actual diff, not just file names; the description must reflect what the code does.
- Check for an existing PR on this branch (`gh pr view --json number,url,body`). If one exists, you are updating its description, not creating a new PR.
- Pick up the ticket ID (e.g. `PROJ-123`) from the branch name or commits, if present.
- If there are uncommitted changes, ask before committing them. Push the branch if it isn't pushed yet.

## 2. Find the template

Use the repo's own GitHub PR template when it has one. Look, ignoring case, in the places GitHub reads:

- `pull_request_template.md` in `.github/`, the repo root, or `docs/`;
- a `PULL_REQUEST_TEMPLATE/` folder in any of those three places, holding several templates. Pick the one that fits the change and say which.

- **Template found:** keep its headings and order. Answer its prompts; don't copy the prompt text into the description. Drop a section only if it truly doesn't apply, or write "None" for sections the team expects to see. Don't add headings it doesn't have.
- **No template:** use [references/fallback-template.md](references/fallback-template.md).

## 3. Write it

- Write for an engineer who knows the codebase but not this change.
- Lead with the why. Name behavior changes, not file lists. Reviewers can see the diff.
- Short bullets, no filler ("This PR...", "Various improvements"), no restating the title.
- Call out anything a reviewer must look at closely: migrations, breaking API changes, config or env changes, security-sensitive code.
- Testing must be honest: say what wasn't verified.
- Link the ticket and related PRs where the template asks, or under Notes.

## 4. Choose a diagram

Add one Mermaid diagram when it shows something prose can't do as quickly. Skip it for small, local, or mechanical changes (renames, dependency bumps, copy edits, one-function fixes).

With the repo's template, put the diagram in the section where it fits best, usually the one that explains what changed. If no section is a natural fit, leave the diagram out rather than adding a heading.

Pick the type that matches what changed:

| What changed | Diagram |
| --- | --- |
| Request flow or interaction between services or components | `sequenceDiagram` |
| Control flow, pipeline, or data flow | `flowchart` |
| Database schema or entity relationships | `erDiagram` |
| Lifecycle or status transitions | `stateDiagram-v2` |
| Module, class, or type structure | `classDiagram` |

Rules:

- Diagram the change, not the whole system. Keep it under ~15 nodes.
- Highlight what's new or changed, e.g. `classDef changed fill:#d4f8d4,stroke:#2da44e` on a flowchart, or a `Note` / `rect` block in a sequence diagram.
- For a change that replaces a flow, a before/after pair is fine if both stay small.
- Use real names from the code (services, tables, functions) so reviewers can map nodes to the diff.
- Make sure it's valid Mermaid. GitHub renders it in a ```` ```mermaid ```` block.

## 5. Publish

- Title: short and imperative, prefixed with the ticket ID when there is one, following the repo's existing PR title style (check `gh pr list --state merged --limit 10`).
- Create with `gh pr create --draft --base <base> --title ... --body-file <file>` (or `gh pr edit <n> --body-file <file>` for an existing PR). Write the body to a temp file rather than passing it inline, so Markdown and backticks survive.
- Return the PR URL.

## Stacks

When the branch sits on another feature branch, it's a layer of a stack, and each PR describes only its own layer.

- **Make sure the branch is in the stack.** Check with `gh stack view`. If it isn't:
  - its base is the default branch, or the branches below aren't in a stack yet: run `gh stack init --base <default branch> <bottom branch> … <this branch>`, which adopts the existing branches bottom to top;
  - the branches below are already a stack: run `gh stack add <this branch>` from a checkout of the branch **directly below** (find it with `git worktree list`). From any other checkout it fails with "not part of a stack".

- **Diff per layer.** For each branch, diff against the branch below it (`git diff <parent>...<branch>`), never against the trunk. A description that mentions a lower layer's changes is wrong.
- **One description per PR.** Write a separate description for every branch that needs one, each following steps 2–4 on its own diff. Add a line at the top of each: `Stack 2/4 · below: #<n> · above: #<n>` (omit missing neighbors).
- **Diagrams stay local.** Each diagram covers only that layer's change. The bottom PR may also get one small overview diagram of the whole stack, if the stack's purpose isn't obvious from the titles.
- **Publish through the stack, not `gh pr create`.** Run `gh stack submit --auto` (the interactive editor doesn't work from a non-interactive shell); it pushes the branches, creates missing PRs as drafts with the right bases, and links the stack on GitHub. Then set each PR's title and body with `gh pr edit <n> --title ... --body-file <file>`, filling in the neighbor PR numbers now that they exist.
- **Updating an existing stack:** only edit the PRs whose layers changed, plus neighbor links if PRs were added or removed.
- Return all PR URLs in stack order, bottom to top.
