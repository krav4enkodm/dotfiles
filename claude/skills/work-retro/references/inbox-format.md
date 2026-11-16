# Retro inbox format

`~/work-work/retros/inbox.md` holds dotfiles fixes found by `work-retro` and not yet applied. `work-retro-apply` (in the dotfiles repo) reads it and moves what it applied to `~/work-work/retros/applied.md`. Both files are local and never committed: they quote the user and name the projects' tickets.

One section per ticket retro, appended at the end:

```markdown
## <repo> <ticket-id> · <YYYY-MM-DD> · <PR url>

- Bucket: <Ticket: missing | Ticket: unclear | Worker | Validator | Coordinator | Setup>
  Quote: «<the user's words or the review comment>»
  Ticket line: «<for Ticket: unclear, the ticket text that was misread>»
  Missing: <what the setup should have known>
  Fix: <path under claude/, e.g. skills/work-plan/references/definition-of-ready.md> → <the change>
```

`applied.md` uses the same entries, each followed by `  Applied: <dotfiles PR url>`.
