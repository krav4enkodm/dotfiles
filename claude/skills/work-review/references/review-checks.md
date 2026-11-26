# What only a reviewer checks

The coding rules (`~/.claude/rules/*.md` and the repo's own) say what good code
looks like, and `rules-reviewer` checks them. This file covers the rest of a
Dmitry review: what he looks at beyond the diff, the bugs he catches, and what
he lets pass.

## Beyond the diff

- **Consumers.** Run `rg` for every changed component, hook, function, prop and export.
  - A new required prop on a shared library is a breaking change.
  - A query added to a shared component runs everywhere that component is used.
  - Removing a field from a shared fragment or type affects every reader.
- **Types.** Open the generated or declared type before claiming anything about nullability. "According to the schema `amount` is always a `number`" must be true.
- **Existing code.** Look for a design-system prop or component, a shared utility, service, constant, enum or fragment that already does it. Link the one you found.
- **Request flow.** Check whether a new query waits on another (a component rendered only after a parent's query resolves), blocks a sibling section, or duplicates a query.
- **Sibling PRs.** If the PR copies a pattern from a recently merged PR, judge it against that PR before flagging it. When copying is deliberate, he lets it pass.

## Ticket and spec

- **Requirements.** Go through the ticket point by point. Flag anything missing or added beyond it ("In the ticket we have this point: … but as I can see in the screenshot above `optional` still appears").
- **Copy and formats.** Labels, amounts, dates, fraction digits, and empty states copied from another entity.
- **Screenshots.** Check alignment and state in the PR's own screenshots.
- **Contradicted claims.** "The ticket says no other component uses this, but there are two."
- **Open questions.** Product or design questions get asked, not guessed: "Could you please clarify with <PM> …", "discuss this UX with designers".
- **Session-recording privacy.** Sensitive inputs need the recorder's privacy attribute. Cross-app impact: "Do you know if it affects the other apps?"

## Bugs he catches: check every one the diff could hit

- `{count && <X />}` renders `0`.
- `0` treated as empty: a falsy check on amounts, or a placeholder shown for `0`.
- Money and `toFixed` rounding, float drift: `(0.005).toFixed(2) // '0.01'`.
- `parseInt(undefined)` → `NaN` (`'NaN'` once stringified).
- `arr[0]` on a possibly empty array.
- `find` where several matches are possible.
- O(n²) membership checks in loops.
- A missing early return after a handled condition.
- A dead branch inside a guard: `isSmall ? '' : x` inside `{!isSmall && …}`.
- An inverted boolean after a rename.
- A `key` lost in a refactor; the index used as `key`.
- A module-level class instance shared by every component instance.
- A request or `setState` after unmount; an uncancelled debounce.
- `useState(initial)` expected to follow prop changes.
- Unstable callbacks or objects passed to third-party widgets, re-triggering requests; a null token leaving the user on a spinner.
- Breakpoint mismatch between a grid and a media-query hook.
- Pagination state that breaks shared links; filters and pagination combined.
- A race between a backend webhook and a frontend query.
- A disabled-but-required field.
- The wrapper element a tooltip on a disabled button needs, removed.
- Enum keys used where values are expected.
- A mock function spread as an object.
- Typos in matchers, double spaces in copy.

## Leftovers

`console.log` or debug calls, commented-out code, a TODO without a ticket ID or with a placeholder one, and placeholder links or copy. After a removal, also check unused translation keys, data files, enum keys, constants, old folders, props, lint disables and dependencies.

## Lets pass

Drop these even when a rule technically applies:

- **Owned by lint, format and CI:** formatting, import order, commit messages, PR descriptions, i18n wording.
- **Equivalent approaches** (switch vs if, text vs colour assertion): "a matter of preferences, and it is up to the developer". At most an "IMO … up to you".
- **A justified lint disable** ("Linter just warn us about potential problems, but this is not our case").
- **Performance with a small, bounded n:** at most "but keep in mind".
- **MVP or temporary scaffolding** with a stated plan.
- **Pre-existing or copied code the PR didn't change:** mention it once at most ("I just wanted to point on it") and offer a follow-up.
- **Files outside your ownership in cross-team PRs, and big upgrades:** "test pass should be enough".
- **An author's reasoned choice:** concede unless it breaks a contract, a single source of truth, honest types or a package boundary.
- **Copy and spacing in mockups that aren't approved.**
- **Accessibility, security and bundle size:** raise them only when concrete.
- **Something the repo's rules allow,** even if the user rules prefer otherwise.
