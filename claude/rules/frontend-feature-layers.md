---
paths:
  - "**/*.{tsx,jsx}"
---

# Frontend feature layers

How to lay out a data-backed feature (page, screen, drawer, modal, widget) in
React code. The repo's own rules (CLAUDE.md, AGENTS.md, `.claude/rules/`, lint
config) and its neighbouring code win where they differ. When a rule file and
the code disagree, follow the rule for new files and match the neighbours when
editing an existing one, and say which you did.

The container reads top to bottom as **fetch → derive → compose**; every
component is pure UI.

## Layers

1. **Data**: the API/GraphQL operations and their generated types. Reuse an
   existing operation before adding one. Never hand-edit generated files;
   regenerate them with the repo's codegen command.
2. **Services**: the logic, unit-tested without React.
   - Pure `get*`/`to*` functions map query shape to view shape (sort, group,
     format, label).
   - `use*` hooks wrap one data operation each, build its variables, and return
     `{ data, loading }`. One hook per file.
   - May import types from the data layer, never from components or containers.
3. **Presentational components**: receive `data`, `loading` and callbacks as
   props, and never touch the data layer.
   - Each owns its own loading, empty and error rendering.
   - One component per file, one per visual section (header, chart, table…).
   - Callbacks are `on<Event>` props defaulting to a no-op; internal handlers
     are `handle<Event>`.
4. **Container**: calls the hooks, passes results through services, holds the
   loading/error flags, and composes the components. No section JSX, no `.map()`,
   no mapping logic.

## Across layers

- **Reuse first.** Search for an existing hook, operation or component before
  writing one, and prefer extending a shared package over a new file.
- **Types flow outward.** Services export the row/result types; components use
  them as prop types. Mocks use the real query types and are deleted when real
  data lands.
- **Package boundaries.** See `package-boundaries`: public entry points only,
  and feature packages depend on shared packages, never on each other.
- **Verify.** Typecheck and lint the changed package, and run its tests. Test
  services, and components with real branching (loading vs data), using the
  repo's existing test setup.

## Smells

- The container imports a formatting, date or label util: move the call into a
  service.
- A component takes a raw query type and maps it inline: map it in a service and
  pass the view type.
- Spinner logic wraps a child in the container: pass `loading` to the child.
- Two components declare the same row shape: export one type from the service.
- A hook or util was copied because the original lived "somewhere else":
  extract it to a shared package instead.
