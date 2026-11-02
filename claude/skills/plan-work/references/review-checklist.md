# Readiness review checklist

Used by the inline review and by the `readiness-reviewer` agent. For each finding, decide: **resolved from code** (fix it, cite evidence) or **question** (a real choice for the user).

## Per ticket

1. **Ships alone safely.** If only this ticket is deployed, what do users, anonymous visitors, or other systems see? Is anything exposed before its guard exists?
2. **Access and trust.**
   - Does a new login method, token, API key, or service account change the meaning of existing "is logged in" / "is staff" checks?
   - Are new endpoints readable by anyone who shouldn't read them (public REST/GraphQL defaults)?
   - Is a client-side guard the only thing protecting server-rendered data?
   - Can a machine account do more than it needs (publish, delete, other collections/tables)?
3. **Data model vs real producers.** Compare fields with what actually produces the data: optional vs required, nulls, empty strings, fallback paths, values that don't exist yet (e.g. a date nobody provides).
4. **Hooks and side effects.** Existing hooks that run on every write (audit fields, "last edited by", revalidation, webhooks): do they behave correctly for the new writer?
5. **Idempotency.** Can it be re-run (retries, manual re-triggers) without duplicates or overwriting human edits?
6. **Provisioning.** Every account, key, secret, variable, and flag: who creates it, where, and is that path possible (e.g. not hidden from the only UI that creates it)?
7. **Runtime constraints.** Where does the code run? Dependencies available there, network reachability, firewall/WAF rules, timeouts, resource limits.
8. **Verification path.** Can the stated "done when" actually be checked in the stated environment? Some flows only run in production.
9. **Library behaviour.** For every framework behaviour the ticket relies on (ordering, defaults, headers, query params), check the installed source and version.
10. **Clarity.** Could someone new implement it without asking? Ambiguous verbs ("handle", "support"), unnamed files, two tickets that both seem to own a part.

## Cross-ticket

1. **Contracts between tickets.** What one ticket sends/stores vs what another accepts/reads: names, formats, required fields, status values.
2. **Scope coverage.** Every part of the goal is owned by exactly one ticket; nothing is orphaned or duplicated.
3. **Dependency links** match real needs; the order makes each prefix of the stack shippable.
4. **Shared decisions** are reflected the same way in every ticket that depends on them.

## Traps seen before

- A rule written as "reject when X" passes a request that simply omits the field; write "allow only when Y".
- A new service account or token silently passes existing `Boolean(user)`-style "is staff" checks.
- A client-only route guard in front of server-rendered data.
- A framework runs access checks before it applies defaults, so the check sees raw input.
- A CI job without a package install, so a script with imports fails at runtime.
- "Blocked by" links copied from the stack order instead of real dependencies.
- A "done when" that names a test style the repo can't run. Check how existing tests reach that code.

Project-specific traps belong in that project's own rules (e.g. `.claude/rules/`), not here.
