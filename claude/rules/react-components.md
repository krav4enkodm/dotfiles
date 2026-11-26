---
paths:
  - "**/*.{tsx,jsx}"
---

# React components and markup

## Contract

- **The parent decides whether a component renders.** Make the data a
  component needs a required prop and guard at the call site
  (`{items.length > 0 && <List items={items} />}`). Don't accept a nullable prop
  and `return null` inside: the component still mounts and runs its hooks.
- **Callbacks the component can't work without are required.** No `noop`
  default inside: a form without `onSave` makes no sense. Tests and stories
  pass a `noop` themselves.
- **A shared component knows nothing about its callers.** No flag that says
  where it's used (`isOnboarding`, `isSettingsPage`) and no copy computed from a
  caller's state; a flag may say what to show (`showDisclaimer`). Keep the
  shared logic inside and let the caller pass what varies: a `ReactNode` slot
  named by its place (`footer`), a render prop, the label, the handler.
- **A new required prop on a shared component is a breaking change.** Check
  every consumer before adding it.

## Props

- **Pass an object when the component uses most of its fields** (a fragment
  object from above is fine). When it uses a few fields of a big object, pass
  those as primitives, so the call site shows what goes in.
- **Keep props balanced:** up to about 8. Beyond that, or instead of drilling
  props through layers, use a slot (`ReactNode` or render prop).
- **No objects or arrays created inline in render** (`data={{ … }}`, `items={[…]}`):
  every render makes a new reference, so the props can't be optimised later
  without reworking them. Pass an existing value: a prop from above, a module
  constant. Inline functions are fine.
- **Variants are a fixed set, defined once inside the component.** Expose
  `variant: 'default' | 'media'` with its styles inside, not a `className` or
  colour override, so every place looks the same. When variants need different
  fields, make the props a discriminated union
  (`{ variant: 'compact'; color: Color } | { variant: 'full' }`), so no code has
  to check which fields are present.
- **Don't assemble a component from a config.** If a config object says which
  form, type and label to use, write one self-contained component per case
  instead; casts and growing conditions in such a component are the sign.
- **Experiments are built for removal.** Gate them in one place where the
  component is used (`{isEnabled && <NewBanner />}`), never by reading the flag
  inside shared components or passing it into services.

## Structure

- **One component per file.** A second real component, even a small one, gets
  its own module.
- **No wrapper without value.** A component used once that only nests or
  combines other components and forwards props is inlined into its parent.
- **Keep the tree flat.** Deep nesting makes it hard to follow what goes where;
  balance depth against component size.

## Markup

- **Every attribute and wrapper has a reason.** No `id`, wrapper, spacer,
  `<br />`, flex or grid container the design doesn't need; stack children
  with the parent's `gap`.
- **Don't restate defaults:** no props equal to the component's default, no
  layout props that do nothing (`justifyContent` without flex).
- **No nested ternaries.** Use an early return, a variable or the parent.
  Prefer `cond && <X />` over `cond ? <X /> : null`. Name an expression before
  `return` when it reads badly inline.
- **Never `count && <X />`**: it renders `0`. Use `count > 0 &&`.
- **Static text is plain JSX text** (`Total: {amount}`), not `{'…'}` or a
  template string.
- **Key list items by a stable id**, never the index, and keep the `key` when
  refactoring a mapped element.
- **Keep the wrapper a tooltip on a disabled button needs.** Disabled elements
  don't fire pointer events.

## Design system and styling

- **Design-system components and props first.** Use its layout, spacing, size,
  variant and loading props before custom CSS or inline `style`, and pick the
  primitive whose props fit instead of restyling another one. Overriding the
  design system is a design decision: check its docs for a built-in option,
  then confirm.
- **No outer spacing inside a component.** Margins and styles that fix the
  parent's layout belong where the component is placed. Styles a component
  always needs belong inside it, not in every caller.
- **Spacing and colour come from tokens,** not raw values.
