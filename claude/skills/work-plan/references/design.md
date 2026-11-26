# Design: tickets and checks

One place for how UI tickets handle the design, used at every step: `work-plan` and the `readiness-reviewer` when planning, the `work-work` worker when building, and the `design-validator` when checking. Skip this file for tickets without a Design section.

## The rule

The design file is the only source of visual values. The ticket says **where** to look and **what the design doesn't say**. It never copies sizes, colours, fonts or spacing into its text: a copy goes stale the moment the design changes, and the validator would then approve the stale value.

## The ticket's Design section

- **Element map.** One line per element the ticket adds or changes: the element, its design node ID (or, for an image mockup, the file and the region), and the design-system component expected to render it (e.g. "Submit button: 12-345, design-system `Button`"; "Invite modal: mockups/invite.png, centre"). Menus, popovers and other open states get their own node.
- **What the design can't show.** Decisions a static frame can't express:
  - which state a frame draws when it isn't the resting one (hover, active, open, selected, loading, disabled), and what the element looks like at rest;
  - existing elements the mockup leaves out, and whether they stay or go;
  - behaviour: what each control does, empty and loading states.
- **Allowed deviations.** Every place the build will knowingly differ from the design, with the reason.

## Pulling a node

With the design tool (for Figma: `get_design_context`, `get_variable_defs`, `get_screenshot`), pull each node's structure, its variables/tokens and what they resolve to, and a screenshot. Every property those variables cover is in scope: typography (size, weight, line height, case), colour and background per state, size, and spacing to neighbours. Checking one property ("colours match") lets a wrong font size pass every review.

For each element, find the design-system component and the prop or token that produces each value. Read the component's defaults in the installed source: font size, title case and margins between siblings often differ from the design silently.

## Planning (`work-plan`, `readiness-reviewer`)

Pull every node and check:
- Every element the Scope adds or changes has a node, and every node exists and shows that element.
- A node drawn in a non-resting state (the context reports `active`, `hover`, `selected`, `open`, or a variant name says so) is a **question** unless the ticket already says what the element looks like at rest.
- Elements on screen today that the mockup omits are a **question** unless the ticket says whether they stay.
- Every element that shows data (an avatar, a date, a count) names the field that feeds it. A field that doesn't exist yet is in some ticket's Scope, or it's a gap.
- A component whose default differs from the design gets the prop named in the ticket.
- The section copies no values; if it does, replace them with the node ID.

## Building (worker)

- Read the ticket's notes on states before pulling nodes: a node drawn as hover, active or open is not the resting look.
- Implement each value through the design-system prop or token that produces it, never a hardcoded value.
- A node with no values to read (no variables, a flattened image) or an image mockup: match the picture with the design system's components and tokens, the same way the `design-validator` will compare it (see below).
- Start the app (see "Running the app" in the brief) and measure each element's computed styles for every property in scope, in each state the ticket names. Stop the app when done.
- Where a value can be asserted cheaply, add it to the component's test (e.g. computed font size), so CI guards it.
- A mismatch you can't fix inside the Scope, or a design question the ticket doesn't answer, is a BLOCKED question.

## Validating (`design-validator`)

The `design-validator` picks one of three methods per element: Figma values (below) where the node has them; the node's screenshot where it doesn't; and for an image mockup, whether the page has the same elements. The agent's file has the details of the last two.

For each element and property in scope, find what produces it in the code and mark the row:
- **met**: a test asserts it, or the code settles it;
- **mismatch**: the code produces a different value, including an unset prop whose default differs;
- **unverified**: nothing in the code or tests settles it.

Apply the ticket's notes on states and allowed deviations: a listed deviation isn't a mismatch. Then measure every unverified row in the running app: start it in the background, open the page, read each property with `get_css_styles` or `getComputedStyle` via `evaluate_script`, and use `hover` and `click` to reach the named states. Only read: don't submit forms or create, change or delete data. Stop the app when done. A measured row becomes met or mismatch; a row you still couldn't check (the app wouldn't start, no browser session) stays unverified and is listed as not independently checked.
