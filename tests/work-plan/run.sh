#!/usr/bin/env bash
# Tests for claude/skills/work-plan/scripts/plan.mjs. Runs from check.sh.
#
# The good fixture must pass `check`; each broken copy of it must fail with the
# expected message; and stamps must go stale when their inputs change.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAN="$HERE/../../claude/skills/work-plan/scripts/plan.mjs"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

FAILED=0
pass() { printf '  \033[32mok\033[0m    %s\n' "$1"; }
fail() { FAILED=1; printf '  \033[31mfail\033[0m  %s\n' "$1"; printf '%s\n' "$2" | sed 's/^/        /'; }

copy() { rm -rf "$TMP/p"; cp -r "$HERE/fixtures/good" "$TMP/p"; }

# expect <label> <exit code> <text the output must contain> <command...>
expect() {
  local label="$1" code="$2" want="$3"; shift 3
  local out rc=0
  out="$("$@" 2>&1)" || rc=$?
  if [ "$rc" = "$code" ] && grep -qF -- "$want" <<<"$out"; then pass "$label"; else fail "$label (exit $rc)" "$out"; fi
}

copy
expect "good plan passes" 0 "check passed" node "$PLAN" check "$TMP/p"

copy
sed -i 's|`web/src/members/Invite/`|`web/src/members/List/InviteButton.tsx`|' "$TMP/p/README.md"
expect "overlap in a wave fails" 1 "tickets 04 and 05 overlap" node "$PLAN" check "$TMP/p"

copy
sed -i 's/^| 3 | 06/| 2 | 06/' "$TMP/p/README.md"
expect "wrong wave fails" 1 "ticket 06 is in wave 2, but its blockers put it in wave 3" node "$PLAN" check "$TMP/p"

copy
sed -i 's/^Covers: U4, R3, E3/Covers: R3, E3/' "$TMP/p/05-invite-modal.md"
expect "uncovered inventory item fails" 1 "U4 (context/ui-inventory.md) is covered by no ticket" node "$PLAN" check "$TMP/p"

copy
sed -i 's/^Covers: R1$/Covers: R1, U9/' "$TMP/p/07-members-real-api.md"
expect "unknown id fails" 1 "covers U9, which isn't defined" node "$PLAN" check "$TMP/p"

copy
sed -i 's/^| 1 | 01 Members API contract | api | — |/| 1 | 01 Members API contract | api | 03 |/' "$TMP/p/README.md"
expect "cycle fails" 1 "have a cycle" node "$PLAN" check "$TMP/p"

copy
sed -i 's/^Wave 2 · blocked by 02\. Renders/Wave 2 · blocked by 01. Renders/' "$TMP/p/04-members-list.md"
expect "first line out of step with the table fails" 1 "04-members-list.md: blockers on the first line differ" node "$PLAN" check "$TMP/p"

# Stamps, staleness and gates on a fresh plan.
P="$TMP/fresh"
expect "init" 0 "plan created" node "$PLAN" init "$P" --slug demo --size task --repo web="$TMP/web"
echo "Show a member count." >"$P/input/concept.md"
expect "stamp recon" 0 "stamped recon" node "$PLAN" stamp "$P" recon
expect "recon is done" 0 "next: brief" node "$PLAN" status "$P"
echo "And a search box." >>"$P/input/concept.md"
expect "changed input makes recon stale" 0 "changed: input/concept.md" node "$PLAN" status "$P"
expect "stale recon closes the brief gate" 1 "recon is stale" node "$PLAN" gate "$P" brief
node "$PLAN" stamp "$P" recon >/dev/null
printf '\n## Q1 · open · blocker · brief\nWhich members count?\n' >>"$P/questions.md"
expect "an open question blocks its stamp" 1 "Q1 (brief, blocker) is open" node "$PLAN" stamp "$P" brief
sed -i 's/^## Q1 · open/## Q1 · applied/' "$P/questions.md"
expect "an applied question doesn't" 0 "stamped brief" node "$PLAN" stamp "$P" brief
expect "split needs a wave table to stamp" 1 "README.md (the wave table) is missing" node "$PLAN" stamp "$P" split
node "$PLAN" stamp "$P" recon >/dev/null
expect "re-stamping recon makes brief stale" 0 "brief      stale" node "$PLAN" status "$P"

exit "$FAILED"
