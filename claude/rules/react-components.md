---
paths:
  - "**/*.{tsx,jsx}"
---

# React components and markup

How a component's contract and markup should look. Complements
`frontend-feature-layers` (where things go) and `react-state-and-data`. The
repo's own rules, design system and neighbouring code win where they differ.

## Contract

- **The parent decides whether a component renders.** Make the data a
  component needs a required prop and guard at the call site
  (`{items.length > 0 && <List items={items} />}`). Don't accept a nullable
  prop and `return null` inside: the component still mounts and runs its hooks.
- **A shared component knows nothing about its callers.** No flags that say
  where it is used (`isOnboarding`, `isEditMode`, `isOverdue`) and no copy
  computed from a caller's state. Keep the shared logic inside and let the
  caller pass what varies: a `ReactNode` slot, a render prop, the label, the
  handler. Name a slot by its place (`footer`), not by one caller's content.
- **Domain copy lives in domain components.** A generic component takes its
  text as required props and has no domain defaults like "No invoices yet".
- **Pass only what's rendered:** the fields the component shows, as flat
  primitive props (`countryCode: string`, not `country: { code }`), not a whole
  query result, class instance or object the child has to dig into.
- **A new required prop on a shared component is a breaking change.** Check
  every consumer before adding it.
- **A component per variant** when variants behave differently (mobile vs
  desktop, payment method A vs B), chosen once at the top, rather than one
  component driven by a config map.
- **Experiments are built for removal.** Gate them in one place where the
  component is used (`{isEnabled && <NewBanner />}`), never by reading the flag
  inside shared components or passing it into services. Give each variant its
  own function.

## Files and size

- **One component per file.** A second real component, even a small one, gets
  its own module next to the first.
- **No wrapper that only forwards props.** Inline a component or `renderX()`
  used once that only adds nesting. Split a component when it grows separate
  layouts or large JSX blocks.
- **Lazy-load heavy content that's rarely shown**, such as a modal's body.

## Markup

- **Every attribute, wrapper and prop has a reason.** Don't add an `id`, an
  extra container, a flex wrapper, a variant or a class you can't explain, and
  don't copy them from elsewhere without knowing why they're there.
- **Don't restate defaults.** No props equal to the component's default
  (`direction="row"` on a row container, the default `variant` or `color`), and
  no layout props that do nothing (`justifyContent` without flex).
- **JSX stays declarative.** Compute values, conditional labels and long
  conditions into named constants before `return`. No nested ternaries: use an
  early return, a variable or the parent. Prefer `cond && <X />` over
  `cond ? null : <X />`.
- **Never `count && <X />`**: it renders `0`. Use `count > 0 &&` or
  `Boolean(count) &&`.
- **Static text is plain JSX text** (`Total: {amount}`), not `{'...'}` or a
  template string, and no stray `{' '}` spacers.
- **Pass handlers by reference** (`onClick={close}`), not `() => close()`.
- **Key list items by a stable id**, never the index, and keep the `key` when
  refactoring a mapped element.
- **Keep the wrapper a tooltip on a disabled button needs.** Disabled elements
  don't fire pointer events.

## Design system and styling

- **Design-system components and props first.** Use its layout, spacing,
  size, variant and loading props before custom CSS, inline `style` or new
  styled components, and pick the primitive whose props fit instead of
  restyling the wrong one. Before overriding it, check the docs for a built-in
  option; a deviation from the design system is a design decision to confirm.
- **No outer spacing inside a component.** Margins and styles that fix the
  parent's layout (`min-width` against flex shrinking) belong where the
  component is placed. Styles a component always needs belong inside it, not
  in every caller.
- **Minimal layout markup.** No empty spacer elements, `<br />`, grid or flex
  wrappers the design doesn't need; stack children with the parent's `gap`.
- **Spacing and colour come from tokens,** not raw values.
