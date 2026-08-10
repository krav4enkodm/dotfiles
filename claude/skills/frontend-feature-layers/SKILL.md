---
name: frontend-feature-layers
description: Separate a data-backed frontend feature into four layers — data, services, presentational components, and a thin container. Use when building or refactoring any frontend page/container/component/screen/drawer/modal/widget that fetches and renders data — the default way to lay out feature code. Container orchestrates; components are presentational; services hold logic; data holds operations. Stack-agnostic; defers to the repo's own conventions where they differ.
---

# Frontend Feature Layers

The default separation of concerns for a data-backed feature. The goal: any engineer can open the container and read it top-to-bottom as **fetch → derive → compose**, and open any component and see pure UI. Logic, data, mapping, UI, and states each live in one predictable place.

## The four layers

**1. Container** — orchestration *only*.
- Fetches data (calls hooks), derives view data (calls pure services), holds `loading`/`error` flags, and composes children.
- Contains **no section JSX and no mapping logic**. If you're writing a `.map()` or a conditional render tree inside the container, it belongs in a service or a component.
- Passes already-derived **data + loading** down as props.

**2. Presentational components** — dumb and self-contained.
- Receive `data` + `loading` (+ callbacks) as props; **never touch the data layer**.
- **Own their own loading / empty / skeleton render.** State rendering lives with the thing that shows it, not hoisted into the container.
- One component per file. Split the view into one component per visual section (header, chart, table, footer, …) rather than one mega-layout.
- Callbacks: `on<Event>` props defaulted to a no-op; internal handlers `handle<Event>`.

**3. Services** — the logic, framework-light and testable.
- **Pure derivation/mapping functions** (`get*`/`to*`): query-shape → view-shape (sort, group, format, label). Unit-tested in isolation. No React.
- **Data-wrapping hooks** (`use*`): wrap a data operation, build its variables/filter, return `{ data, loading }`. One hook per file.
- A service may import a *type* from the data layer, but not depend on components/containers.

**4. Data** — operations only.
- The API/GraphQL operation + its generated types. Reuse existing operations before adding new ones. Regenerate types with codegen; never hand-edit generated files.

## Build sequence (and where each piece goes)

1. **Data**: is there an existing operation/hook? Reuse it. Else add the operation.
2. **Services**: a `use*` hook to fetch + shape variables; pure `get*` functions to map results into view data.
3. **Components**: one presentational component per section, each taking `data`/`loading`, owning its states.
4. **Container**: wire hooks → services → components. Keep it thin.
5. **States**: loading/empty/error rendered *inside* the component that owns that region.

## Cross-cutting rules

- **Reuse first.** Before creating a hook/operation/component, search for an existing one (and prefer extending the most basic existing shared package over a new file). Don't reinvent shared primitives.
- **Types flow outward.** Export result/row types from services and use them as component prop types — a single source of truth, no re-declaring shapes.
- **Mocks mirror real shapes.** Placeholder data is typed as the *real* query-result types so it's swap-ready; delete mocks as real data lands. Keep unresolved/backend-blocked fields clearly marked.
- **Respect package boundaries.** Import a package's public API (its entry point), never another package's internals (`src/…`); feature packages depend on shared packages, never on each other. If a shared primitive lives in the wrong place, extract it to a shared package rather than reaching across the boundary.
- **Naming.** PascalCase components (folder + file), `use*` hooks, `get*`/`to*` pure functions. For folder casing elsewhere, follow the repo.
- **Verify.** Typecheck + lint the changed package + run colocated unit tests. Not every leaf needs a test; test services (logic) and components with real branching (loading vs data).

## Smell tests

- Container imports a formatting/date/label util → move that call into a service.
- A component takes a raw query type and maps it inline → map in a service, pass the view type.
- Loading spinner logic sits in the container around a child → push `loading` into the child.
- Two components re-declare the same row/item shape → export one type from the service.
- Copy-pasted a hook/util because the original was "somewhere else" → check boundaries; extract to a shared package instead.

## Adapt to the repo

This skill is the *separation discipline*. The repo owns the *specifics* — read them first and let them win:

- **Agent/editor rule files** — `AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, `CONTRIBUTING.md`. Where these exist they are authoritative on folder shape, naming, and imports. Don't restate them; follow them.
- **Neighbouring code** — open the closest sibling feature and match its layout, import style, and test setup.
- **When a rule file and the surrounding code disagree**, follow the rule for *new* files, match the neighbours only when editing an existing one, and say which you did. Never silently propagate a pattern the repo is trying to move away from.
- **Test setup** — find how components are actually tested (runner, shared render wrapper, mocking helpers) and reuse it rather than introducing a second pattern. If the repo's docs and its test files disagree, trust the files and flag the gap.
- **Design system** — check whether UI comes from a shared package and how it's imported (single barrel vs per-component packages). Match the mandated style for new files.
- **Codegen** — if data types are generated, find the generate command and never hand-edit the output.

Repo-specific notes, where they're worth keeping, belong in that repo (its rules files) rather than in this skill.
