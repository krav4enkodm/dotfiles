# Personal defaults

Applies in every project. A repo's own CLAUDE.md / AGENTS.md wins where they differ.

## Git and GitHub

- Never commit to the default branch. Branch off it first.
- Commit or push only when asked. Follow the repo's commit conventions (see the
  `commit` skill); the body says why, not what.
- PRs are drafts. Never mark one ready, merge, or request reviewers unless asked.
- Never post on GitHub on my behalf: no comments, replies, reviews or
  resolved threads on PRs, issues or discussions, unless I explicitly ask for
  that post. Don't offer to either; tell me what you found and let me reply.
- If git has no identity in a repo, stop and ask. Don't make one up or pass
  `-c user.name=...` yourself.

## Working

- Discover the repo's check commands (tests, lint, typecheck) from its docs and
  task runner, and run them before saying a change is done.
- Never kill a process you didn't start, such as a dev server already on a port.
- Keep secrets out of commits, PR text and logs. Never read credential files
  unless asked.
