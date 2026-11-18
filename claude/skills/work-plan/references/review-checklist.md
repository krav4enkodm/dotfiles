# Readiness review checklist

Used by the inline review and by the `readiness-reviewer` agent. For each finding, decide: **resolved from code** (fix it, cite evidence) or **question** (a real choice for the user).

## Per ticket

1. **Ships alone safely.** If only this ticket is deployed, what do users, anonymous visitors, or other systems see? Is anything exposed before its guard exists?
2. **Access and trust.**
   - Does a new login method, token, API key, or service account change the meaning of existing "is logged in" / "is staff" checks?
   - Are new endpoints readable by anyone who shouldn't read them (public REST/GraphQL defaults)?
   - Is a client-side guard the only thing protecting server-rendered data?
   - Can a machine account do more than it needs (publish, delete, touch other resources)?
3. **Data model vs real producers.** Compare fields with what actually produces the data: optional vs required, nulls, empty strings, fallback paths, values that don't exist yet (e.g. a date nobody provides).
4. **Hooks and side effects.** Existing hooks that run on every write (audit fields, "last edited by", revalidation, webhooks): do they behave correctly for the new writer?
5. **Idempotency.** Can it be re-run (retries, manual re-triggers) without duplicates or overwriting human edits?
6. **Provisioning.** Every account, key, secret, variable, and flag: who creates it, where, and is that path possible (e.g. not hidden from the only UI that creates it)?
7. **Runtime constraints.** Where does the code run? Dependencies available there, network reachability, firewall/WAF rules, timeouts, resource limits.
8. **Verification path.** Can the stated "done when" actually be checked in the stated environment? Some flows only run in production.
9. **Library behaviour.** For every framework behaviour the ticket relies on (ordering, defaults, headers, query params), check the installed source and version.
10. **Clarity.** Could someone new implement it without asking? Ambiguous verbs ("handle", "support"), unnamed files, two tickets that both seem to own a part, a first line that contradicts Scope.
11. **Design (UI tickets).** Run the planning checks in [design.md](design.md).
12. **Smallest change.** For each change the Scope prescribes: which Done-when item needs it, and would a reviewer ask "is this necessary?" Cut what nothing needs, and replace a prescribed structure with the outcome when simpler code would meet it. A port adapts the source to this repo's components and tokens; it doesn't copy the source's markup and classes.
13. **Bug (bug tickets).** The steps reproduce it on the current code, or the failing path is found in the code. The root cause is named, or is a question. The regression test can reach that path the way the repo's existing tests do.

## Cross-ticket

1. **Contracts between tickets.** What one ticket sends/stores vs what another accepts/reads: names, formats, required fields, status values.
2. **Scope coverage.** Every part of the goal is owned by exactly one ticket; nothing is orphaned or duplicated.
3. **Dependency links** match real needs and have no cycles; each wave, shipped on top of the waves before it, is safe on its own. Each ticket's first line and the wave table agree with the links.
4. **Shared decisions** are reflected the same way in every ticket that depends on them.
5. **No overlap inside a wave.** List the files each ticket in a wave changes. If two share a file, move the shared change into an earlier ticket, or block one on the other.
6. **Contracts come first.** A contract two parallel tickets share (API shape, type, schema field) lives in a ticket in an earlier wave, not written separately into each.
7. **Fan-in is rare and late.** A ticket with two or more blockers waits for all but one of them to merge. Flag any that sit early in the plan or could lose a blocker with a different cut.
8. **Waves are as wide as the code allows.** Flag blockers that are only order, and long chains that a different cut would run side by side.

## Traps seen before

- A rule written as "reject when X" passes a request that simply omits the field; write "allow only when Y".
- A client-only route guard in front of server-rendered data.
- A framework runs access checks before it applies defaults, so the check sees raw input.
- A CI job without a package install, so a script with imports fails at runtime.
- A "done when" that names a test style the repo can't run. Check how existing tests reach that code.

Project-specific traps belong in that project's own rules (e.g. `.claude/rules/`), not here.
